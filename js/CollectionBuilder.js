/* 
 * This file contains a class that supports 
 * the facility for building on-the-fly 
 * collections on the BBTI site. It is 
 * adapted from AnthBuilder.js, written 
 * for the DVPP site. 
*/

/* A collection is essentially just
 * a URL query string as follows:
 * 
 * collTitle=My%Collection&records=1234;1235;1236
 *
 * The record numbers can be converted into full 
 * links very straightforwardly.
 * 
 * When the user is on the create_collection.html page,
 * this class handles generating the URI/link which 
 * will display the collection on the collection.html
 * page. When on the collection.html page, the class
 * parses the URL location to figure out what is 
 * needed, then retrieves all the individual record
 * pages, extracts their core content, and displays
 * them on the page.
*/

//Global variable for object we'll create.
let collBuilder = null;

/* Let's handle this with a class. */
/** @class CollectionBuilder
  * @description This class parses a URL search string
  * and then retrieves all the information it needs to
  * create a collection of individual BBTI trader records.
  * A collection consists of a text title and an ordered 
  * sequence of records. 
  * 
  * The collection title and the array of numeric record ids
  * are both stored in properties of the object, but they
  * can be written to the location query string and read 
  * from it.
  */
class CollectionBuilder{
/** 
  * constructor
  * @description The has no parameters; it simply initializes
  * an instance of a URLSearchParams object and determines
  * whether to proceed and create a collection or not.
  * 
  * It searches in the page for a specific div/@id in which
  * to place its content.
  * @param {Object} options Provides values for various properties
  *                         (all of which have defaults).
  *              
  */
  constructor(options){
    //We do HTML retrieval, so we will need headers.

    this.collHtmlFetchHeaders = {
      credentials: 'same-origin',
      cache: 'default',
      headers: {'Accept': 'text/html'},
      method: 'GET',
      redirect: 'follow',
      referrer: 'no-referrer'
    };
    this.collXmlFetchHeaders = {
      credentials: 'same-origin',
      cache: 'default',
      headers: {'Accept': 'text/xml'},
      method: 'GET',
      redirect: 'follow',
      referrer: 'no-referrer'
    };

    this.regexpId = (options.regexpId === undefined)? '\\d+' : options.regexpId;
    //Construct the full regex from the id regex. This is used 
    //to validate URL parameters.
    this.reIdList = new RegExp('^' + this.regexpId + '(;' + this.regexpId + ')*$');

    //The sanitized anthology title.
    this.collTitle = '';

    //An array for the record ids.
    this.arrRecordIds = [];

    //A relative path for retrieving records.
    this.recordPath = 'orgs/';

    //A map to store our records in. 
    this.mapRecords = new Map();

    //A variable to contain a map of record ids to info.
    this.recordData = null;

    //First figure out where we're going to output the TOC if we create one.
    this.targDiv = document.getElementById('recordCollection');

    //We need a DOMParser to parse retrieved stuff.
    this.parser = new DOMParser();

    //If it's not there, create it.
    if (this.targDiv == null){
      this.targDiv = document.createElement('div');
      this.targDiv.setAttribute('id','recordCollection');
      document.querySelector('main').appendChild(this.targDiv);
    }

    //If we're on the anthology page, we need to set stuff up.
    if (document.documentElement.getAttribute('id') === 'collection'){
      if (this.readFromLocation()){
        this.buildCollection();
      }
    }
    //If we're on the createCollection page, we need to add some handlers.
    if (document.documentElement.getAttribute('id') === 'create_collection'){
      let that = this;
      document.querySelectorAll('#collectionTitle, #recordIds').forEach(
        el => {el.addEventListener('input', function(){this.buildCollectionUri()}.bind(that));}
      );
      this.buildCollectionUri();
    }
  }
/**
  * @function CollectionBuilder~buildCollection
  * @description Retrieves the information required to build the
  * record collection. This is async because it depends on
  * retrieving record pages to create the table.
  * @return {boolean} true if successful, false if not.
  */
  async buildCollection(){    
    //Now we construct an array of promises to retrieve the bits of the collection, 
    //and when they're all resolved, we can build the content for the page.
    let self = this;
    let promises = [];
    for (let i=0; i<this.arrRecordIds.length; i++){
      promises[promises.length] = fetch(this.recordPath + 'org_' + this.arrRecordIds[i] + '.html',
                                        this.anthXmlFetchHeaders)
        .then(function(response){
          if (!response.ok){throw new Error('Failed to retrieve record.');}
          return response.text();
        })
        .then(function(html){
          let doc = this.parser.parseFromString(html, 'text/xml');

//DONE TO HERE.
          let div = doc.querySelector("div[class='org']");
          if (div !== null){
            this.mapRecords.set(i+1, div);
          }
          else{
            div = document.createElement('div');
            div.setAttribute('class', 'org');
            div.appendChild(document.createTextNode('Record with id ' + this.recordIds[i] + ' not found.'));
            this.mapRecords.set(i+1, div);
          }
        }.bind(self))
        .catch(function(e){
          alert('Error attempting to retrieve record for id ' + this.arrRecordIds[i] + '. Does this record exist?');
        }.bind(self));
    }

    Promise.allSettled(promises).then(() => {

      let h2 = document.createElement('h2');
      h2.appendChild(document.createTextNode(this.collTitle));
      document.body.insertBefore(this.targDiv, h2);

      for (let i=1; i<=this.arrRecordIds.length; i++){
        if (this.mapRecords.has(i)){
          this.targDiv.appendChild(this.mapRecords.get(i));
        }
      }
      return true;
    });
    return false;
  }

  /**
  * @function CollectionBuilder~writeToLocation
  * @description Writes the current values of the title and the 
  * record ids into a URL query string and pushes to the History
  * object. Note: this is not currently used, but may be useful
  * at some point, so we retain it.
  * @return {boolean} true if successful, false if not.
  */
  writeToLocation(){
    try{
      let q = '?collTitle=' + encodeURIComponent(this.anthTitle);
      q += '&records=' + this.arrRecordIds.join(';');
      let url = window.location.href.split(/[?#]/)[0] + q;
      history.pushState({time: Date.now()}, '', url);
      return true;
    }
    catch(e){
      console.log('ERROR: ' + e.message);
      return false;
    }
  }
/**
  * @function CollectionBuilder~readFromLocation
  * @description Retrieves a specific collection from the current
  * page URL query string.
  * @return {boolean} true if successful, false if not.
  */
  readFromLocation(){
    try{
      //Read the query string.
      this.usp = new URLSearchParams(document.location.search.substring(1));

      //Retrieve and sanitize the title.
      let title = decodeURIComponent(this.usp.get('collTitle'));
      let sanitizedTitle = this.parser.parseFromString('<p>' + title + '</p>', 'text/html').documentElement.textContent.replace(/[<>]+/g, '');

      //If the result is anything, then we proceed.
      if (sanitizedTitle.length < 3){
        sanitizedTitle = '[No title provided]';
      }

      this.collTitle = sanitizedTitle;

      //Now the poems.
      let recordIdList = decodeURIComponent(this.usp.get('records'));
      //If it's null, then we're OK, we just have a title but no poems yet.
      if (recordIdList == null){
        return true;
      }

      //We insist on it consisting only of semicolon-separated integers.
      if (!recordIdList.match(this.reIdList)){
        console.log('String of record ids is ill-formed.');
        return false;
      }
      this.arrRecordIds = recordIdList.split(';');
      return true;

    }
    catch(e){
      console.log('ERROR: ' + e.message);
      return false;
    }
  }

/**
  * @function CollectionBuilder~buildCollectionUri
  * @description This is triggered by a change in the collection title
  *              field or the record id text area on the createCollection
  *              page. It updates the URI for the collection by rebuilding it.
  * @return {boolean} true if successful, false if not.
  */
  buildCollectionUri(){    
    try{
      let q = '?collTitle=' + encodeURIComponent(document.getElementById('collectionTitle').value);
      let recordIdList = document.getElementById('recordIds').value;
      let recordIds = recordIdList.replace(/[^0-9]+/, ' ').trim().split(/\s+/);
      q += '&records=' + recordIds.join(';');
      let url = window.location.href.replace('create_collection\.html', 'collection.html') + q;
      document.getElementById('collectionLink').setAttribute('href', url);
      document.getElementById('collectionUri').value = url;
      return true;
    }
    catch(e){
      console.log('ERROR: ' + e.message);
      return false;
    }
  }

}

window.addEventListener('load', function(){collectionBuilder = new CollectionBuilder({})});
