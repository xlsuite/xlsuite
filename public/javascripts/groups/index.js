function fetchGroupDetails(e) {
  var element = Event.element(e);

  var url = element.getAttribute("href");
  $("group_details_throbber").show();
  $("close_group_details_indicator").hide();
  new Ajax.Updater("group_details", url, {
      method: "get",
      evalScripts: true,
      onComplete: function() {
        new Effect.Fade("group_details_throbber", {duration: 0.33});
        $("group_details_actions").show();
        $("group_details").show();
      }});

  Event.stop(e);
}

function submitGroupDetails(e) {
  var element = Event.element(e);

  $("close_group_details_indicator").show();
  var group_id_element = $("group_details").down("input[id=group_id]");
  var group_id = group_id_element.value;
  group_id_element.remove();
  new Ajax.Request("/admin/groups/" + group_id, {
      method: "put", 
      evalScripts: true,
      parameters: Form.serialize($("group_details"))
    });
}

Event.observe(window, "load", function() {
  $$("#groups a").each(function(e) {
    Event.observe(e, "click", fetchGroupDetails);
  });

  Event.observe($("close_group_details"), "click", submitGroupDetails);
});
