Event.observe(window, "load", function() {
  var multi_selector = new MultiSelector($('files_list'), 10);
  multi_selector.addElement($('first_file_element'));
});
