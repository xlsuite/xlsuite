Event.observe(window, "load", function() {
  $$("#assets a.details").each(function(e) {
    Event.observe(e, "click", function(e) {
      var anchor = Event.element(e);
      if (anchor.tagName.toLowerCase() != "a") anchor = anchor.up("a");

      Effect.toggle(anchor.id.sub("_toggle", ""));
      Event.stop(e);
    });
  });
});
