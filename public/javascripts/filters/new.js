function showNewLabelForm(element) {
  var selectedOptionValue = element.options[element.selectedIndex].value;
  if(selectedOptionValue == "new_label")
    $('new_label_form').show();
}

function addFilterLine() {
  var num = parseInt($("num_of_filter_line").value) + 1;
  $("num_of_filter_line").value = num+'';
  new Insertion.Bottom("filter_line_fieldsets", 
    "<fieldset id='filter_line_"+num+"'>\n"
+   "  <select id=\"filter_line["+num+"][field]\" name=\"filter_line["+num+"][field]\"><option value=\"from\">From</option><option value=\"to\">To</option><option value=\"subject\">Subject</option><option value=\"body\">Body</option></select>\n"
+   "  <select id=\"filter_line["+num+"][operator]\" name=\"filter_line["+num+"][operator]\"><option value=\"eq\">Equals</option><option value=\"start\">Starts with</option><option value=\"contain\">Contains</option><option value=\"end\">Ends with</option></select>\n"
+   "  <input id=\"filter_line["+num+"][value]\" type=\"text\" name=\"filter_line["+num+"][value]\" autocomplete=\"off\"/>\n"
+   "  Exclude <input id=\"filter_line["+num+"][exclude]\" class=\"box\" type=\"checkbox\" value=\"1\" name=\"filter_line["+num+"][exclude]\"/>\n"
+   "  <a href=\"#\" onclick=\"removeFilterLine("+num+");return false;\">Remove line</a>\n"
+   "</fieldset>\n");
}

function removeFilterLine(num){
  var el_id = "filter_line_"+num;
  $(el_id).remove();
}
