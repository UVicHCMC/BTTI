/*
Library for creating a sortable table. Depends on there being thead with ths or 
tds and tbody in the table.

This needs to find any table which has a "sortable" class, and make the headers
clickable to sort the table. 

Martin Holmes August 2013, tweaked 2018. Based on an earlier attempt from 2011.

This new version should allow multiple tables on the same page, and avoids the use 
of an id for the active triangle.
*/

//Add an event listener to the onload event.
window.addEventListener('load', makeTablesSortable, false);

//The array used to stash table rows before
//sorting them.
var rows = new Array();

//A class for containing a row and associated sort key.
function RowObj(){
  this.row = null;
  this.sortKey = '';
}

//Up and down pointing triangles used for showing direction of sort.
//var upTriangle = '&#x25b2;';
//var downTriangle = '&#x25bc;';
var upTriangle = '\u25b2';
var downTriangle = '\u25bc';

//Utility function.
String.prototype.trim = function () {
    return this.replace(/^\s*/, "").replace(/\s*$/, "");
}

function makeTablesSortable(){
//Find each table with the correct class attribute and make them sortable.
  var tables = document.getElementsByTagName('table');
  for (var i=0; i<tables.length; i++){
    if (tables[i].className.search(/\bsortable\b/) != -1) {
        makeSortable(tables[i]);
    }
  }
}

function makeSortable(table){
  var headers = table.getElementsByTagName('th');
  if (headers.length < 1){
    var theads = table.getElementsByTagName('thead');
    if (theads.length > 0){
      headers = theads[0].getElementsByTagName('td');
    }
  }
  for (var i=0; i<headers.length; i++){
    headers[i].style.cursor = 'pointer';
    headers[i].setAttribute('onclick', 'sortByCol(this, ' + i + ')');
    headers[i].setAttribute('title', 'Click to sort the table by this column.');
    var triangle = document.createElement('span');
    triangle.style.paddingLeft = '0.5em';
    triangle.setAttribute('class', 'sortTriangle');
    triangle.textContent = downTriangle;
    headers[i].appendChild(triangle);
  }
}

//Flag for not interrupting running operations.
var sortInProgress = false;

//Remember which sort we last did.
var lastSortCol = 0;
var sortAsc = true;

/* The actual sorting function. */
function sortByCol(sender, sortCol){
//Check the flag.
  if (sortInProgress == true){return;}
  
//Set the flag.
  sortInProgress = true;
  
//Get a pointer to the ancestor table element.
  var table = sender;
  while (table.tagName.toLowerCase() != 'table'){
    table = table.parentNode;
  }
  
//Set the table cursor to wait. NB: This absolutely fails to work.
  table.style.cursor = 'progress';
  
//Clear the existing array.
  rows = [];

//Find its tbody. Assume there's only one.
  var tbodies = table.getElementsByTagName('tbody')
  if (tbodies.length <1) return;
  
  var tbody = tbodies[0];
  
//This is used to check what kind of data we're sorting on.
  var textSort = false;
  
//Detach all the rows.
  var tbodyRows = tbody.getElementsByTagName('tr');
  
  for (var i=tbodyRows.length-1; i>=0; i--){
    var rowCells = tbodyRows[i].getElementsByTagName('td');

    var sortKey = '';
    if (rowCells.length > sortCol){
      sortKey = rowCells[sortCol].textContent.toLowerCase().trim();
      
      if (sortKey.length > 0){
        textSort = (isNaN(sortKey) || textSort);
      }
    }
    var rowObj = new RowObj();
    rowObj.row = tbodyRows[i].parentNode.removeChild(tbodyRows[i]); 
    rowObj.sortKey = sortKey;
    rows.push(rowObj);
  }

  //Set to default.
  sortAsc = true;

//Now figure out which direction to sort in.
  var triangles = sender.getElementsByClassName('sortTriangle');
  if (triangles.length > 0){
    var triangle = triangles[0];
    if (triangle.className.indexOf('activeSortTriangle') > -1){
      if (triangle.textContent == downTriangle){
        sortAsc = false;
        triangle.textContent = upTriangle;
      }
      else{
        triangle.textContent = downTriangle;
      }
    }
    else{
//Remove the active class from any previous triangle
      var oldActiveTriangles = table.getElementsByClassName('activeSortTriangle');
      for (var i=0; i<oldActiveTriangles.length; i++){
        oldActiveTriangles[i].textContent = downTriangle;
        oldActiveTriangles[i].className = 'sortTriangle';
      }
//Now set the right content and style for the active one.
      triangle.className = 'sortTriangle activeSortTriangle';
      triangle.textContent = downTriangle;
    }
  }

//Sort them.
  if (textSort == true){
    sortAsc ? rows.sort(textSortAsc) : rows.sort(textSortDesc);
  }
  else{
    sortAsc ? rows.sort(numSortAsc) : rows.sort(numSortDesc);
  }

//Re-attach them to tbody.
  for (var i=0; i<rows.length; i++){
    tbody.appendChild(rows[i].row);
  }
  
//Set the table cursor back to the default.
  table.style.cursor = 'default';

//Remember which column.
  lastSortCol = sortCol;
  
//Unset the flag.
  sortInProgress = false;
}

//Comparator functions
function textSortAsc(a, b){
//alert(a.sortKey + ' : ' + b.sortKey + ' = ' + ((a.sortKey < b.sortKey) ? -1: ((a.sortKey > b.sortKey) ? 1 : 0)));
  return ((a.sortKey < b.sortKey) ? -1: ((a.sortKey > b.sortKey) ? 1 : 0));
}
function textSortDesc(a, b){
  return ((b.sortKey < a.sortKey) ? -1: ((b.sortKey > a.sortKey) ? 1 : 0));
}
function numSortAsc(a, b){
  return (parseFloat(a.sortKey) - parseFloat(b.sortKey));
}
function numSortDesc(a, b){
  return (parseFloat(b.sortKey) - parseFloat(a.sortKey)); 
}

