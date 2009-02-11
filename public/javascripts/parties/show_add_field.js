function showAddFieldFocus() {
  var elements = $(this.newElementName).getElementsBySelector("input", "select", "textarea");
  if (elements.length > 1) {
    elements.first().focus();
  }
}

function showAddFieldAfter() {
  Element.hide("optionsToggle_throbber");
  Element.show(this.newElementName)
  showAddFieldFocus();
}

function showAddField(event) {
  Element.hide("optionsToggle");
  Element.show("contactOptions");

  Event.stop(event);
}

function showAddFieldGo(event, target) {
  Event.stop(event);
  if ($F("contactOptions_values") == "") return;

  var selectedItem = $("contactOptions_values").options[$("contactOptions_values").selectedIndex];
  if (null != selectedItem) {
    if (selectedItem.getAttribute("url") == null) {
      showAddFieldGoMissingField(selectedItem, target);
    } else {
      showAddFieldGoContactRoute(selectedItem, target);
    }
  }

  Element.hide("contactOptions");
  Element.show("optionsToggle");

  $("contactOptions_values").selectedIndex = 0;
}

function showAddFieldGoMissingField(selectedItem, target) {
  target.showEditor(selectedItem.getAttribute("value"));
}

function showAddFieldGoContactRoute(selectedItem) {
  var url = selectedItem.getAttribute("url");
  var target = selectedItem.getAttribute("target");
  this.newElementName = selectedItem.getAttribute("newname");
  new Ajax.Updater($(target), url, {method: "get",
      insertion: Insertion.Bottom, evalScripts: true,
      onComplete: showAddFieldAfter.bindAsEventListener(this)});
  Element.show("optionsToggle_throbber");
}

function showAddFieldCancel(event) {
  Element.show("optionsToggle");
  Element.hide("contactOptions");
  Element.hide("optionsToggle_throbber");

  Event.stop(event);
}

function showAddFieldUpdateMissingFields() {
  var template = new Template('<option class="blank_field" value="#{name}">#{title}</option>');

  $$("#contactOptions_values option.blank_field").each(Element.remove);
  $$(".blank").each(function(element) {
    var name = element.id;
    var field = $(element.id.replace("_show", "_field"));
    var field_name = field.getAttribute("name");
    var title = field_name.substring(field_name.lastIndexOf("[") + 1).gsub("]", "").split("_").join(" ").capitalize();
    var prefix = null;
    if (field.getAttribute("blank_prefix") != null) {
      prefix = $F(field.getAttribute("blank_prefix"));
    }

    new Insertion.Bottom("contactOptions_values",
        template.evaluate({name: name, title: prefix ? prefix + ": " + title : title}));
  });
}
