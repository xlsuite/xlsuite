function addToProductCategorySelection(src, target, hiddenField, url) {
  var srcelem = $(src);
  var destelem = $(target);

  if (srcelem.selectedIndex >= 0) {
    var selected = srcelem.options[srcelem.selectedIndex];
    
    var categoryIds = $(hiddenField).value.split(",");
    if (categoryIds.indexOf(selected.value) >= 0) {
      Ext.Msg.show({
        width: 200,
        msg: selected.text + " catalog category has been added",
        buttons: Ext.MessageBox.OK
      });        
      return false;
    }

    var newsel = selected.cloneNode(true);

    myindent = selected.getAttribute('indent');
    for (var i = srcelem.selectedIndex - 1; i >= 0; i--) {
      var el = srcelem.options[i];
      if (myindent > el.getAttribute('indent')) {
        newsel.text = el.text + ' / ' + newsel.text;
        myindent = el.getAttribute('indent');
      } else if (myindent < el.getAttribute('indent')) {
        break;
      }
    }

    Element.removeClassName(newsel, 'indent0');
    Element.removeClassName(newsel, 'indent1');
    Element.removeClassName(newsel, 'indent2');
    Element.removeClassName(newsel, 'indent3');
    Element.removeClassName(newsel, 'indent4');

    destelem.appendChild(newsel);
    updateSelectedCategories(destelem, hiddenField, url);
  }
}

function removeFromProductCategorySelection(target, hiddenField, url) {
  target = $(target);
  if (target.selectedIndex >= 0) {
    var opt = $(target).options[target.selectedIndex];
    target.removeChild(opt);
    updateSelectedCategories(target, hiddenField, url);
  }
  else {
    Ext.Msg.show({
      width: 200,
      msg: "Please specify a selected catalog category to be removed",
      buttons: Ext.MessageBox.OK
    });        
  }
}

function clearProductCategorySelection(target, hiddenField, url) {
  target = $(target);
  while (target.options.length > 0) {
    target.removeChild(target.options[0]);
  }

  updateSelectedCategories(target, hiddenField, url);
}

function updateSelectedCategories(src, hiddenField, url) {
  src = $(src);
  var selected = [];
  for (var i = 0; i < src.options.length; i++) {
    selected.push(src.options[i].value);
  }

  $(hiddenField).value = selected.join(',');
  
  if (url != undefined) {
    var params = {};
    params["product[category_ids]"] = $F(hiddenField);
    Element.show(hiddenField + "_indicator");
    new Ajax.Request(url, {
      method: 'put',
      parameters: params,
      onComplete: function() { Element.hide(hiddenField + "_indicator"); }
    });    
  }
}