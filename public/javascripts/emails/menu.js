function processEmailTemplateSelection() {
  var optionValue = $('email_template').options[$('email_template').selectedIndex].value;
  if (optionValue.match(/^\d+/)) {
    
    new Ajax.Request('/admin/templates/' + optionValue, {
      method: "get",
      asynchronous:true, 
      evalScripts:true,
		  onLoaded:function(request){
		    $("email_template_throbber").hide(); 
		    $("email_template").disabled = false;
		  }, 
		  onLoading:function(request){
		    $("email_template").disabled = true;
		    $("email_template_throbber").show();
		  } 
    });
  }
}

function addGroupToTosField(){
  var groupName = $('group_selection').options[$('group_selection').selectedIndex].value;
  appendToRecipients(groupName);
}

function addTagToTosField(){
  var tagName = $('tag_selection').options[$('tag_selection').selectedIndex].value
  appendToRecipients("tag=" + tagName);
  if ($("email_tags_to_remove") != null) {
    $("email_tags_to_remove").value = tagName;
  }
}

function addSearchToTosField(){
  var searchName = $('search_selection').options[$('search_selection').selectedIndex].value
  appendToRecipients("search=" + searchName);
}

function addAccountOwnerToTosField() {
  var tagName = $('all_tag_selection').options[$('all_tag_selection').selectedIndex].value;
  appendToRecipients("account_owners=" + tagName);
  if ($("email_tags_to_remove") != null) {
    $("email_tags_to_remove").value = tagName;
  }
}

function displaySecondSelection(selectedIndex) {
  var select = $("email_tos_selection");
  var optionValue = select.options[select.selectedIndex].value;

  hideGroupSelection();
  hideTagSelection();
  hideSearchSelection();   
  hideAccountOwnerSelection();   

  if (optionValue.match(/group/i)) {
    showGroupSelection();
  }
  else if (optionValue.match(/tag/i)) {
    showTagSelection();
  }
  else if (optionValue.match(/search/i)) {
    showSearchSelection();
  }
  else if (optionValue.match(/account owner/i)) {
    showAccountOwnerSelection();
  }
  else {
    // Don't care
  } 
}

function appendToRecipients(value) {
  if (value.toString() == "") return;

  var newValue = $F("email_tos") + ", " + value;
  var normalizedValue = newValue.sub(/^,/, '').sub(/^\s+/, '');
  $("email_tos").value = normalizedValue;
}

function showGroupSelection() {
  changeSelectedIndexToDefaultSelectedIndex('group_selection')
  $("collection_of_groups").show();
}

function hideGroupSelection() {
  $("collection_of_groups").hide();
}

function hideAccountOwnerSelection() {
  $("collection_of_tags").hide();
}

function showAccountOwnerSelection() {
  changeSelectedIndexToDefaultSelectedIndex('all_tag_selection')
  $("collection_of_all_tags").show();
}

function showTagSelection() {
  changeSelectedIndexToDefaultSelectedIndex('tag_selection')
  $("collection_of_tags").show();
}

function hideTagSelection() {
  $("collection_of_tags").hide();
}

function showSearchSelection() {
  changeSelectedIndexToDefaultSelectedIndex('search_selection')
  $("collection_of_searches").show();
}

function hideSearchSelection() {
  $("collection_of_searches").hide();
}