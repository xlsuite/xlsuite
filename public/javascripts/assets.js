Event.observe(window, "load", function() {
  $("asset_zip_file").observe("change", function() {
    if ($("asset_zip_file").checked) {
      $$("#assets_edit_options").each(Element.hide);
    } else {
      $$("#assets_edit_options").each(Element.show);
    }
  });
});
