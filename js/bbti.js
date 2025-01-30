/*             bbti.js                */
/*        Author: Martin Holmes.      */
/*        University of Victoria.     */

/** This file is part of the projectEndings BBTI
  * project.
  *
  * Free to anyone for any purpose, but
  * acknowledgement would be appreciated.
  * 
  * This file is provided as an example of how a project
  * might implement support for highlighting search hits
  * in a target page by including some simple JS in all
  * pages on the site. It can most likely be used as-is
  * in your project, but if your pages already have a lot
  * of code that runs on page load, this may interfere 
  * with it, so may have to be customized and integrated
  * with your existing code.
  */

 /** WARNING:
   * This lib has "use strict" defined. You may
   * need to remove that if you are mixing this
   * code with non-strict JavaScript.
   */

/* jshint strict:false */
/* jshint esversion: 6*/
/* jshint strict: global*/
/* jshint browser: true */

"use strict";

//This is the var which will be an instance of the checkboxAligner
//class.
var cbAligner;

/** @class checkboxAligner
  * @description This class creates an object whose job is 
  *              to align the county and city checkbox collections,
  *              such that whichever counties are checked, the only
  *              city/town options visible are those within those 
  *              counties.
  * 
  *              It can be instantiated on any page, which will cause
  *              the JSON it needs to be downloaded and presumably cached,
  *              but obviously it will do nothing unless the search 
  *              controls are present on the page. 
  */
class checkboxAligner{
    constructor(){
      //Headers used for all AJAX fetch requests.
      this.fetchHeaders = {
        credentials: 'same-origin',
        cache: 'default',
        headers: {'Accept': 'application/json'},
        method: 'GET',
        redirect: 'follow',
        referrer: 'no-referrer'
      };
      //Array mapping to be constructed from JSON.
      this.citiesToCounties = null;
      this.cityCheckboxes = document.querySelectorAll('fieldset[title *= "City"]>ul.ssDescCheckboxList input[type="checkbox"]');
      this.countyCheckboxes = document.querySelectorAll('fieldset[title *= "County"]>ul.ssDescCheckboxList input[type="checkbox"]');
      if (this.countyCheckboxes.length > 0){
        this.getJson();
      }
    }
    async getJson(){
        let fch = await fetch('js/citiesToCounties.json', this.fetchHeaders)
        .then(function(response){return response.json();})
        .then(function(json){this.citiesToCounties = json}.bind(this));
        this.setupCheckboxDependencies();
        //console.log(this.citiesToCounties.type);
    }
    /**
     * @function checkboxAligner~setupCheckboxDependencies
     * @description This method assigns an onchange event to county selection
     *              checkboxes, so that the city/town checkboxes available are
     *              limited to those from the selected counties.
     */
    setupCheckboxDependencies(){
        console.log('Setting up checkbox dependencies.')
        this.countyCheckboxes.forEach(
            cb => {cb.addEventListener('change', function(){this.alignCheckboxes(cb);}.bind(this))});
    }
    /**
     * @function checkboxAligner~alignCheckboxes
     * @description This method performs the alignment by retrieving the 
     *              list of selected counties, then checking each city 
     *              and either showing it or unchecking and hiding it.
     * @param {HTMLInputElement} sender The checkbox which has triggered
     *                            the function.
     */
    alignCheckboxes(sender){
        //console.log(sender.getAttribute('value'));
        let selCounties = [];
        this.countyCheckboxes.forEach(cb => {if (cb.checked){selCounties.push(cb.value)}});
        //console.log(selCounties);
        this.cityCheckboxes.forEach(cb => 
            {
                if (selCounties.length < 1){
                    cb.parentNode.style.display = '';
                }
                else{
                    let counties = this.citiesToCounties.cities[cb.value];
                    //console.log(counties);
                    if (counties){
                        let intersect = selCounties.filter(x => counties.includes(x));
                        if (intersect.length > 0){
                            cb.parentNode.style.display = '';
                        }
                        else{
                            cb.checked = false;
                            cb.parentNode.style.display = 'none';
                        }
                    }
                }
            }
        );
    }
}

/**
 * const ssResultsMutation is a function triggered as a callback from a 
 *                       MutationObserver; its purpose is to notice when
 *                       a search has been completed and results shown,
 *                       and trigger some further actions.
 */
const ssResultsMutation = mutations => {
    mutations.forEach(mutation => {
        if (mutation.type === 'childList'){
            cbAligner.alignCheckboxes(null);
            bbtiSearchFinished(mutation.target.querySelectorAll('ul>li').length);
        }
    })
}

/**
 * const ssResultsObserver MutationObserver watches the results div
 *                         for changes.
 */
const ssResultsObserver = new MutationObserver(ssResultsMutation);

/**
 * @function bbtiSearchFinished
 * @description This function is plugged into the StaticSearch
 *              searchFinishedHook, enabling us to perform extra
 *              processing on the results of a search.
 * @param {number} num A response flag we don't actually need to use.
 */
function bbtiSearchFinished(num){
    //console.log(`Hits: ${num}`);
    const regex = /^orgs\/org_(\d+)\.html$/;
    let p = document.getElementById('viewResultsAsCollection');
    //Check the number of results received.
    if (num > 0 && num < 51){
        let divResults = document.getElementById('ssResults');
        //Iff it's within range, then construct the URL.
        let hitLinks = divResults.querySelectorAll('a[href]');
        let orgNums = [];
        hitLinks.forEach(h => {orgNums.push(h.getAttribute('href').replace(regex, '$1'))});
        let url = 'collection.html?collTitle=Search%20results&records=' + orgNums.join(';');
        //console.log(url);
        //Create the link and insert it into the page.
        
        let a = document.createElement('a');
        a.setAttribute('href', url);
        a.appendChild(document.createTextNode('View these results as a collection.'));


        if (p != null){
            p.innerHTML = '';
            p.appendChild(a);
        }
        else{
            p = document.createElement('p');
            p.setAttribute('id', 'viewResultsAsCollection');
            p.appendChild(a);
            divResults.parentNode.insertBefore(p, divResults);
        }
    }
    else{
        if (p != null){
            p.parentNode.removeChild(p);
        }
    }
}

//How do we hook this up? Do we add it to the class, or
//to the already-instantiated Sch object -- in which case
//how do we know when it's instantiated?

/**
 * Instantiate on load.
 */
window.addEventListener('load', function(){
    cbAligner = new checkboxAligner();
    ssResultsObserver.observe(document.getElementById('ssResults'), {childList: true});
});