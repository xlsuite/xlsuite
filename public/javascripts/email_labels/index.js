function toggleEmailLabelRename(id){
  var form = id + "_rename_form";
  $(form).toggle();
  var label = id + "_rename";
  $(label).toggle();
}
