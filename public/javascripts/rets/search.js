var XlSuiteSingleTemplate, XlSuiteDualTemplate;

Event.observe(window, "load", function() {
  Event.observe($("search_resource"), "change", updateClassesFromResource);
  Event.observe($("search_class"), "change", updateFieldsFromSearchClass);
  Event.observe($("field"), "change", updateFieldValues);
  Event.observe($("operator"), "change", updateOperatorFields);
  Event.observe($("add_query_component"), "click", addQueryComponent);
  new Ajax.Autocompleter('search_tag_list', 'search_tag_list_auto_complete',
      '/admin/listings;auto_complete_tag', {
          paramName: 'q',
          indicator:'search_tag_list_indicator',
          tokens:[',',' '],
          method: 'get'});


  XlSuiteDualTemplate = new Template('\
<li>\
  <div style="display:none">\
    <input type="hidden" name="line[#{index}][field]" value="#{field_value}"/>\
    <input type="hidden" name="line[#{index}][operator]" value="#{operator_value}"/>\
    <input type="hidden" name="line[#{index}][from]" value="#{from_value}"/>\
    <input type="hidden" name="line[#{index}][to]" value="#{to_value}"/>\
  </div>\
  <span class="field">#{field_text}</span>\
  <span class="operator">#{operator_text}</span>\
  <span class="value">\
    <span class="from">#{from_text}</span>\
    <span>and</span>\
    <span class="to">#{to_text}</span>\
  </span>\
  <a href="#" class="remove">Remove</a>\
</li>');

  XlSuiteSingleTemplate = new Template('\
<li>\
  <div style="display:none">\
    <input type="hidden" name="line[#{index}][field]" value="#{field_value}"/>\
    <input type="hidden" name="line[#{index}][operator]" value="#{operator_value}"/>\
    <input type="hidden" name="line[#{index}][from]" value="#{from_value}"/>\
    <input type="hidden" name="line[#{index}][to]" value="#{to_value}"/>\
  </div>\
  <span class="field">#{field_text}</span>\
  <span class="operator">#{operator_text}</span>\
  <span class="value">#{from_text}</span>\
  <a href="#" class="remove">Remove</a>\
</li>');

});

function updateClassesFromResource() {
  $("search_resource_indicator").show();
  new Ajax.Updater("search_class", "/admin/rets;classes",
      { method: "get",
        parameters: "resource=" + encodeURIComponent($F("search_resource")),
        onComplete: function() {$("search_resource_indicator").hide()}
      });
}

function updateFieldsFromSearchClass() {
  $("search_class_indicator").show();
  new Ajax.Updater("field", "/admin/rets;fields",
      { method: "get",
        parameters: "resource=" + encodeURIComponent($F("search_resource")) + "&class=" + encodeURIComponent($F("search_class")),
        onComplete: function() {$("search_class_indicator").hide()}
      });
}

function updateFieldValues() {
  var select = $("field");
  var option = select.options[select.selectedIndex];
  var lookupName = option.getAttribute("lookup");

  $("field_indicator").show();
  new Ajax.Updater("from", "/admin/rets;lookup",
      { method: "get",
        parameters: "resource=" + encodeURIComponent($F("search_resource")) + "&id=" + encodeURIComponent(lookupName),
        onComplete: function() {$("field_indicator").hide()}
      });
}

function updateOperatorFields() {
  var value = $F("operator");
  if (value == "between") {
    $("to_value").show();
  } else {
    $("to_value").hide();
  }
}

function addQueryComponent() {
  var field = $("field").options[$("field").selectedIndex];
  var operator = $("operator").options[$("operator").selectedIndex];
  var valueFrom = $("value_from");
  var valueTo = $("value_to");

  values = new Hash();
  values["field_value"] = field.value;
  values["field_text"] = field.firstChild.data;
  values["operator_value"] = operator.value;
  values["operator_text"] = operator.firstChild.data;
  values["from_value"] = valueFrom.value;
  values["from_text"] = valueFrom.options ? valueFrom.options[valueFrom.selectedIndex].firstChild.data : valueFrom.value;
  values["to_value"] = valueTo.value;
  values["to_text"] = valueTo.options ? valueTo.options[valueTo.selectedIndex].firstChild.data : valueTo.value;
  values["index"] = $("query").childNodes.length;

  var template = null;
  if (operator.value == "between") {
    template = XlSuiteDualTemplate;
  } else {
    template = XlSuiteSingleTemplate;
  }

  new Insertion.Bottom("query", template.evaluate(values));
  $$("#query > li:last-child > a.remove").each(function(e) {
    Event.observe(e, "click", removeQueryElement.bindAsEventListener(e));
  });

  valueFrom.value = "";
  valueTo.value = "";
}

function removeQueryElement() {
  this.up("li").remove();
  Event.stop();
}
