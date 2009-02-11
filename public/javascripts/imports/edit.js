function sendAJAXRequestToUpdateMappings(selectElement) {
	var selectedID = selectElement.options[selectElement.selectedIndex].value;
	$("defaultMapperSelection_throbber").show();
	if (selectedID==0) {
  	new Ajax.Request("/admin/imports/" + $("import_id").value + ";edit", {
	  	method: "get"
	  });
	}
	else { 
  	new Ajax.Request("/admin/mappers/" + selectedID + ";edit", {
	  	method: "get"
	  });
	}
}

function displayOverwriteMapperConfirmationBox(msg, mapperID) {
  message = msg + "\nWould you like to overwrite?";
  var win = window.confirm(message);
  if (win) {
  	new Ajax.Request("/admin/mappers/" + mapperID, {
	    method: "put",
		  asynchronous:true, 
		  evalScripts:true, 
		  onLoaded:function(request){$("saveTemplateMapping_throbber").hide()}, 
		  onLoading:function(request){$("saveTemplateMapping_throbber").show()}, 
		  parameters:Form.serialize($("import_form"))
		});    
  }
  return false;
}

function submitImportAndMappingForm(){
  new Ajax.Request('/admin/mappers', {
	  asynchronous:true, 
	  evalScripts:true, 
		onLoaded:function(request){$("saveTemplateMapping_throbber").hide()}, 
		onLoading:function(request){$("saveTemplateMapping_throbber").show()}, 
	  parameters:Form.serialize('import_and_mapper_form')
  }); 
	return false;	
}

function onLoad() {
	$("defaultMapperSelection").selectedIndex = 0;
}

Event.observe(window, "load", onLoad);