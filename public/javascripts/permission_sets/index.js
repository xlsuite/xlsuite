function fetchPermissionSetDetails(e) {
  var element = Event.element(e);

  var url = element.getAttribute("href");
  $("permission_set_details_throbber").show();
  $("close_permission_set_details_indicator").hide();
  new Ajax.Updater("permission_set_details", url, {
      method: "get",
      evalScripts: true,
      onComplete: function() {
        new Effect.Fade("permission_set_details_throbber", {duration: 0.33});
        $("permission_set_details_actions").show();
        $("permission_set_details").show();
      }});

  Event.stop(e);
}

function submitPermissionSetDetails(e) {
  var element = Event.element(e);

  $("close_permission_set_details_indicator").show();
  var permission_set_id_element = $("permission_set_details").down("input[id=permission_set_id]");
  var permission_set_id = permission_set_id_element.value;
  permission_set_id_element.remove();
  new Ajax.Request("/admin/permission_sets/" + permission_set_id, {
      method: "put", 
      evalScripts: true,
      parameters: Form.serialize($("permission_set_details"))
    });
}

Event.observe(window, "load", function() {
  $$("#permission_sets a").each(function(e) {
    Event.observe(e, "click", fetchPermissionSetDetails);
  });

  Event.observe($("close_permission_set_details"), "click", submitPermissionSetDetails);
});
