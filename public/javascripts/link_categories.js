function toggleBlind(source, target) {
  blindUp = new Image()
  blindUp.src = "/images/icons/bullet_toggle_minus.png"
  blindDown = new Image()
  blindDown.src = "/images/icons/bullet_toggle_plus.png"
  if ($(source).src==blindDown.src) {
    Effect.BlindDown(target,{duration:0.1})
    $(source).src = blindUp.src
    $(source).alt = "Bullet_toggle_minus"
  }
  else {
    Effect.BlindUp(target,{duration:0.1})
    $(source).src = blindDown.src
    $(source).alt = "Bullet_toggle_plus"
  }
}

function updateSelectedLinkCategories(display_name, id) {
  var selected = $('selected_link_categories');
  for(var i=0; i < selected.length; i++) {
    sel = selected.options[i];
    if (sel.value==id) {
      selected.removeChild(sel);
      Element.removeClassName('link_to_update_selected_link_categories_'+id, 'selected_link_category')
      updated_selection_values = new Array()
      for(var i=0; i < selected.length; i++) {
        updated_selection_values.push(selected.options[i].value)
      } 
      $('link_category_ids').value = updated_selection_values.join(',');
      return
    }
  }
  var newsel = new Option(display_name, id, false)
  selected.appendChild(newsel)
  Element.addClassName('link_to_update_selected_link_categories_'+id, 'selected_link_category')
  updated_selection_values = new Array()
  for(var i=0; i < selected.length; i++) {
    updated_selection_values.push(selected.options[i].value)
  } 
  $('link_category_ids').value = updated_selection_values.join(',');
}

function initializeHighlightSelectedLinkCategories(ids) {
  var array_of_ids = ids.split(',')
  for(var i=0; i < array_of_ids.length; i++) {
    Element.addClassName('link_to_update_selected_link_categories_'+array_of_ids[i], 'selected_link_category')
  }
}