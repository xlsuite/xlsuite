var MillisPerDay = 24*60*60*1000;

function formatDate(date) {
  if (null == date) { return ''; }
  var day = date.getDate();
  var month = 1 + date.getMonth();
  var year = date.getFullYear();

  return numberToZeroPaddedString(month, 2) + '/' + numberToZeroPaddedString(day, 2) + '/' + numberToZeroPaddedString(year, 4);
}

function numberToZeroPaddedString(number, padding) {
  var str = '0000' + number.toString();
  return str.substring(str.length - padding);
}

Object.extend(Date.prototype, {
  addDays: function(numberOfDays) {
    return new Date(this.getTime() + numberOfDays * MillisPerDay);
  },
  addMonths: function(numberOfMonths) {
    return new Date(this.getTime() + numberOfMonths * 30 * MillisPerDay);
  },
  addYears: function(numberOfYears) {
    return this.addMonths(12 * numberOfYears);
  }
});

function appendVarToBody(target, element) {
  element = $(element);
  target = $(target);
  target.value =    target.value.substring(0, target.selectionStart)
                  + element.innerHTML
                  + target.value.substring(target.selectionEnd);
  Field.focus(target);
}

/* Runs through all unchecked INPUT[type=checkbox] elements of +container+, checks them,
 * and then calls the optional callback method with true and the list of newly checked elements.
 *
 * If +options+ has a key named +selector+, use this selector instead of the default one.
 *
 * Callback:
 *   function(newValue, elements) {}
 */
function selectAll(container) {
  var options = arguments[1] || {};
  var callback = options['callback'] || Prototype.emptyFunction;
  var selector = options['selector'] || "input[type=checkbox]";

  var unselected = $(container).getElementsBySelector(selector).inject([], function(memo, e) {
    if (!e.checked) memo.push(e);
    return memo;
  });

  unselected.each(function(e) {
    e.checked = true;
  });

  callback(true, unselected);
}

/* Runs through all checked INPUT[type=checkbox] elements of +container+, unchecks them,
 * and then calls the optional callback method with false and the list of newly unchecked elements.
 *
 * If +options+ has a key named +selector+, use this selector instead of the default one.
 *
 * Callback:
 *   function(newValue, elements) {}
 */
function deselectAll(container) {
  var options = arguments[1] || {};
  var callback = options['callback'] || Prototype.emptyFunction;
  var selector = options['selector'] || "input[type=checkbox]";

  var selected = $(container).getElementsBySelector(selector).inject([], function(memo, e) {
    if (e.checked) memo.push(e);
    return memo;
  });
  
  selected.each(function(e) {
    e.checked = false;
  });

  callback(false, selected);
}

function changePageSize(e) {
  var uri = window.location.href;
  var parts = uri.split("?", 2);
  var params = "";

  if (parts.length == 2) {
    params = parts[1].gsub(/show=(?:\d+|all)/i, "").gsub(/page=\d+/, "").gsub(/&{2,}/, "&").gsub(/&$/, "");
  }

  params += "&show=" + this.value;
  window.location = (parts[0] + "?" + params).gsub(/\?&/, "?");
}

Event.observe(window, "load", function() {
  $$("select.pager").each(function(e) {
    Event.observe(e, "change", changePageSize.bindAsEventListener(e));
  });
});


function applyTagTo(tagName, fields, options) {
  [fields].flatten().each(function(field) {
    var element = $(field);
    var showElementId = field.split("_")
    showElementId.pop();
    showElementId.push("show");
    
    var showElement = $(showElementId.join("_"));
    var value = element.value;

    var re = new RegExp('(^|[ ,])' + tagName + '(?=[ ,]|$)'); 
    if (null == value.match(re)) {
      value += ', ' + tagName;
    } else {
      value = value.gsub(re, RegExp.$1);
    }

    value = value.gsub(/\s+/, ' ').sub(/^\s+/, '').sub(/\s+$/, '').sub(/,?\s*$/, '').gsub(/,\s*,/, ', ').gsub(/^\s*,/, '');

    element.value = value;
    
    if (showElement) {
      showElement.innerHTML = value;
    }
  });
  
  if (typeof(options) == "undefined") return;
  if (typeof(options.afterUpdate) == 'function') options.afterUpdate();
}

function refreshHorizontalNavBar(oldScrollY){
  var scrollY = getWindowScrollY();
	if (oldScrollY == scrollY){
	  $('header').style.top = scrollY + "px";
    $('header').show();		
	}
	else{
		hideHorizontalNavBar();
	}
}

function hideHorizontalNavBar(){
  $('header').hide();	
}

function showHorizontalNavBar(){
  $("header").show();	
}

function moveHorizontalNavBar(){
  hideHorizontalNavBar();
	var scrollY = getWindowScrollY();
  window.setTimeout("displayHorizontalNavBar("+ scrollY +")", 500)
}

function displayHorizontalNavBar(oldScrollY){
	if (oldScrollY == getWindowScrollY()){
    $('header').style.top = oldScrollY + "px";
		showHorizontalNavBar();
	}
}

function getWindowScrollY(){
	var scrollY = 0;
	if ( document.documentElement && document.documentElement.scrollTop ){
		scrollY = document.documentElement.scrollTop;
  }
	else if ( document.body && document.body.scrollTop ){
    scrollY = document.body.scrollTop;
  }
	else if ( window.pageYOffset ){
    scrollY = window.pageYOffset;
  }
	else if ( window.scrollY ){
    scrollY = window.scrollY;
  }
	return scrollY;	
}

Event.observe(window, "load", function() {
  //Event.observe(window, "scroll", moveHorizontalNavBar);
});

function changeSelectedIndexToDefaultSelectedIndex(id) {
  var defaultIndex = 0
  for(i=0; i<=$(id).length-1; i++){
    var option = $(id).options[i]
    if (option.defaultSelected) { 
      $(id).selectedIndex = option.index;
      break;
    }
  }
}

function changeSelectedIndexToZero(id) {
  $(id).selectedIndex = 0;
}

function uncheckAllCheckBoxes() {
  $$('input[type="checkbox"]').each(function(element) {
    element.checked = false;
  })
}

function showAdditionalQEFields(element){
  var selectedOptionValue = element.options[element.selectedIndex].value;
  if (selectedOptionValue == "email")
    $('quick-entry-subject-field').show();
  else
    $('quick-entry-subject-field').hide();
}

function calculateMarginPercentage(relativeSrc ,baseSrc, renderTo) {
  var relativeValue = $(relativeSrc).value;
  var baseValue = $(baseSrc).value;
  var margin = 0;
  relativeValue = relativeValue.replace(/[^\d.]/gi, "");
  baseValue = baseValue.replace(/[^\d.]/gi, "");
  relativeValue = parseFloat(relativeValue);
  baseValue = parseFloat(baseValue);
  if (relativeValue != baseValue && baseValue != 0 && !isNaN(baseValue) && !isNaN(relativeValue)) {
    margin = (Math.round(((relativeValue / baseValue) - 1)*10000)/100).toString();
  }
  $(renderTo).innerHTML = margin + "%";
}
