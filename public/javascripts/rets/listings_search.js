var searchResourceOldSelectedIndex = 0;
var searchClassOldSelectedIndex = 0;

Event.observe(window, "load", function() {
  Event.observe($("search_resource"), "change", updateClassesFromResource);
  Event.observe($("search_class"), "change", updateFieldsFromSearchClass);
  Event.observe($("search_resource"), "click", updateSearchResourceOldSelectedIndex);
  Event.observe($("search_class"), "click", updateSearchClassOldSelectedIndex);
  changeSelectedIndexToDefaultSelectedIndex("search_resource");
  changeSelectedIndexToDefaultSelectedIndex("search_class");
  updateSearchClassOldSelectedIndex();
  updateSearchResourceOldSelectedIndex();
});

function updateSearchResourceOldSelectedIndex() {
  searchResourceOldSelectedIndex = $("search_resource").selectedIndex;
}
function updateSearchClassOldSelectedIndex() {
  searchClassOldSelectedIndex = $("search_class").selectedIndex;
}

function updateSearchResourceSelectedIndex() {
  $("search_resource").selectedIndex = searchResourceOldSelectedIndex;
}
function updateSearchClassSelectedIndex() {
  $("search_class").selectedIndex = searchClassOldSelectedIndex;
}

function updateClassesFromResource() {
  var state = window.confirm("Changing Table will remove all extra search parameters, are you sure?")
  if (state) {
    $("search_class").disabled = true;
    $("search_resource_indicator").show();
    new Ajax.Updater("search_class", "/admin/rets;classes",
        { method: "get",
          parameters: "resource=" + encodeURIComponent($F("search_resource")),
          onComplete: function() {$("search_resource_indicator").hide(); $("search_class").disabled = false;}
        });
    removeAllExtraSearchParameters();
  }
  else {
    // brings back search_resource to the old selected index
    updateSearchResourceSelectedIndex();
    $("search_class").disabled = false;
  } 
}

function updateFieldsFromSearchClass() {
  var state = window.confirm("Changing Class will remove all extra search parameters, are you sure?")
  if (state) {
    /*$("search_class_indicator").show();
    new Ajax.Updater("field", "/admin/rets;fields",
        { method: "get",
          parameters: "resource=" + encodeURIComponent($F("search_resource")) + "&class=" + encodeURIComponent($F("search_class")),
          onComplete: function() {$("search_class_indicator").hide()}
        });*/
    removeAllExtraSearchParameters();
  }
  else {
    // brings back search_class to the old selected index
    updateSearchClassSelectedIndex();
  }
}

function updateFieldValues(selectionElement) {
  var toBeChangedElement = selectionElement.up("td").next().next().down("span");
  var inputName = toBeChangedElement.down().getAttribute("name");
  var option = selectionElement.options[selectionElement.selectedIndex];
  var lookupName = option.getAttribute("lookup");
  var throbber = selectionElement.next(".throbber");
  throbber.show();
  new Ajax.Updater(toBeChangedElement.id, "/admin/rets;lookup",
      { method: "get",
        parameters: "resource=" + encodeURIComponent($F("search_resource")) + "&id=" + encodeURIComponent(lookupName) + "&name=" + encodeURIComponent(inputName),
        onComplete: function() {throbber.hide()}
      });
}

function showLineToInputField(selectionElement) {
  var optionValue = selectionElement.options[selectionElement.selectedIndex].value;
  var lineToSpan = selectionElement.up('td').next().down('span');
  if (optionValue.match(/between/i)) {
    lineToSpan.show();
  }
  else {
    lineToSpan.hide();
  }
}

function removeAllExtraSearchParameters() {
  var lastCounter = parseInt($("last_counter_of_search_lines").value);
  var element = null;
  for (i=15; i<=lastCounter; i++) {
    element = $("line_"+ i +"_parameters");
    if (element) {
      element.remove();
    }
  } 
}

function removeThisSearchLine(linkToRemove) {
  linkToRemove.up("tr").remove();
}