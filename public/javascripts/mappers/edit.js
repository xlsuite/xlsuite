var TRANSFORMATION_OPTIONS = ["As-is", "Lowercase", "Stripped", "Titleize", "Uppercase"];

function changeSelectedTransformationTo(selectedTransformation, rowNumber) {
	$("mappings[map][" + rowNumber + "][tr]").selectedIndex = TRANSFORMATION_OPTIONS.indexOf(selectedTransformation) || 0;
}

function clearAllMappings() {
	var numOfMappingRows = parseInt($("num_of_mapping_rows").value)
	for(i=1; i<=numOfMappingRows; i++){
		// clear hidden field values
	  $("mappings[map][" + i + "][model]").value = "";
	  $("mappings[map][" + i + "][field]").value = "";
	  $("mappings[map][" + i + "][name]").value = "";
    // clear innerHTML of mapping
		var row = getMappingRowBasedOnMappingIndex(i);
    var mappingElement = row.down(".mapping").down(".mapping");
		showAnItemInTheListOfMappingColumns(mappingElement.innerHTML);
		mappingElement.innerHTML = "";
		// change selection to default value "As-is"
		$("mappings[map][" + i + "][tr]").selectedIndex = 0;
	}
}

function getMappingIndex(e) {
	return e.up("tr").down(".mappingIndex").innerHTML;
}

function getMappingRowBasedOnMappingIndex(idx){
	var element = null;
	$$("td.mappingIndex").each(function(e) {
		if (parseInt(e.innerHTML) == idx) {
			element = e.up("tr");
		}
	});
	return element;  	
}

function updateMappingHiddenFieldValues(e, model, field, nameAttr) {
  var mappingIndex = getMappingIndex(e);
	$("mappings[map][" + mappingIndex + "][model]").value = model;
	$("mappings[map][" + mappingIndex + "][field]").value = field;
	$("mappings[map][" + mappingIndex + "][name]").value = nameAttr;
}

function getMappingHiddenFieldValues(draggable) {
	var array = new Array();
  var mappingIndex = getMappingIndex(draggable);
	array.push($("mappings[map][" + mappingIndex + "][model]").value);
	array.push($("mappings[map][" + mappingIndex + "][field]").value);
	array.push($("mappings[map][" + mappingIndex + "][name]").value);
	return array;	
}

function switchMappingHiddenFieldValues(x, y) {
  var xAttributes = getMappingHiddenFieldValues(x);
  var yAttributes = getMappingHiddenFieldValues(y);
  updateMappingHiddenFieldValues(x, yAttributes[0], yAttributes[1], yAttributes[2]);
  updateMappingHiddenFieldValues(y, xAttributes[0], xAttributes[1], xAttributes[2]);
}

function processDrop(draggable, droppable) {
	var draggableInnerHtml = draggable.innerHTML;
	var draggablePartOfList = $$('#listOfImportColumns dd').include(draggable);
	
	// move down to the next node if the next node has mapping class
  if (droppable.down('.mapping')) {
		droppable = droppable.down('.mapping');
	}
	
	var droppableInnerHtml = droppable.innerHTML;
	if (!draggable.hasClassName("persistent")) { 
		// hide draggable if the element does not have 'persistent' class name 
		//   but belongs to the available column list
	  if (draggablePartOfList) {
	    draggable.hide();
			// if droppableInnerHtml contains something show the item in the list that belongs to
    	if (droppableInnerHtml) {
    		showAnItemInTheListOfMappingColumns(droppableInnerHtml);
    	}
		}
  	// switch innerHTML of the draggable element with the droppable innerHTML
		//   if the draggable element does not belong to the column list and does not have 'persistent' class
		else {
			draggable.innerHTML = droppableInnerHtml;
		}
	}
	
	// replace the innerHTML value of the droppable
	droppable.innerHTML = draggable.getAttribute("text") || draggableInnerHtml;
	
	// if draggable is part of the list of columns, update the hidden field values that correspond
	//   with the mapping row(droppable element)
	// else switch the attributes of hidden fields that correspond to the swapped mapping rows
	if (draggablePartOfList) {
	  var model = "";
  	var field = "";
  	var nameType = "";
	  model = draggable.getAttribute("model");
		field = draggable.getAttribute("field");
		nameAttr = draggable.getAttribute("name");
  	updateMappingHiddenFieldValues(droppable, model, field, nameAttr);
	}
	else {
		switchMappingHiddenFieldValues(draggable, droppable);
	}
	
	// makes the droppable to become draggable 
	makeElementDraggable(droppable);
	droppable.show();
}

function clearThisMappingRow(clearMappingLink){
	clearMappingLink.up('tr').getElementsByClassName("mapping").each(function(e) {
    if (e.down('.mapping')) {
  		e = e.down('.mapping');
	  }
		showAnItemInTheListOfMappingColumns(e.innerHTML);
		e.innerHTML = "";
		updateMappingHiddenFieldValues(e, "", "","");
	})
}

function showAnItemInTheListOfMappingColumns(nameOfList){
	$$("#listOfImportColumns dd").each(function(e) {
		if (e.getAttribute("text") == nameOfList) {
	    e.show();
		}
	});
}

function processDropToInitialContainer(draggable, droppable) {
	showAnItemInTheListOfMappingColumns(draggable.innerHTML);
	updateMappingHiddenFieldValues(draggable, "", "", "");
	if (!$$('#listOfImportColumns dd').include(draggable)) {
	  draggable.innerHTML = ""
	}
}

function createDroppingContainer(){
  Droppables.add($('listOfImportColumns'), {accept: "mappingColumn", hoverclass: "hover", onDrop: processDropToInitialContainer});	
}

function initializeMappingColumns(force){
	var numOfMappingRows = parseInt($("num_of_mapping_rows").value)
	for(i=1; i<=numOfMappingRows; i++){
		e = getMappingRowBasedOnMappingIndex(i);
		var model = $("mappings[map][" + i + "][model]").value
		var field = $("mappings[map][" + i + "][field]").value
		var nameAttr = $("mappings[map][" + i + "][name]").value
		var element = getElementBasedOnAttributes(model, field, nameAttr);
		if (element) {
		  mappingElement = e.down(".mapping").down(".mapping")
			mappingElement.innerHTML = element.getAttribute("text");
			makeElementDraggable(mappingElement);
		  element.hide();
		}
		if (force) {
		  var selectedOptionIndex = 0
		  for(j=0; j<=$("mappings[map][" + i + "][tr]").length-1; j++){
			  var option = ($("mappings[map][" + i + "][tr]").options)[j]; 
			  if (option.defaultSelected) {
				  selectedOptionIndex = option.index;
			    break;
			  }
		  }
		  $("mappings[map][" + i + "][tr]").selectedIndex = selectedOptionIndex;
		}
	}
}

function getElementBasedOnAttributes(model, field, nameAttr){
  var element = "";
	$$("#listOfImportColumns dd.draggable").each(function(e) {
		if (e.getAttribute("model") == model && e.getAttribute("field") == field && e.getAttribute("name") == nameAttr) {
			element = e;
		}
	})
	return element;	
}

function makeElementDraggable(e) {
	new Draggable(e, {revert: true});
	if (!e.hasClassName("draggable")) {
		e.addClassName("draggable");
	}
	if (!e.hasClassName("mappingColumn")) {
		e.addClassName("mappingColumn");
	}
}

function onLoad() {
  $$("#listOfImportColumns .draggable").each(function(e) {
    new Draggable(e, {revert: true});
  });
  
  $$("#mappingsTable .mapping").each(function(e) {
		Droppables.add(e, {accept: "mappingColumn", hoverclass: "hover", onDrop: processDrop});
  });
	
	createDroppingContainer();
	initializeMappingColumns(true);
	$('listOfImportColumns').show();
	initializeAvailableMappingsColumnSize();
}

function initializeAvailableMappingsColumnSize() {
	$('listOfImportColumns').style.height = ($("mappingsTable").clientHeight - $("mappingsTable").down('thead').clientHeight) + "px";
	$('listOfImportColumns').show();
}

Event.observe(window, "load", onLoad);
