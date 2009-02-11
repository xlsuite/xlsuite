Event.observe(window, "load", function() {
  Element.show("throbber");
  setInterval(updateFutureStatus, $F("refresh_interval"));
});

function updateFutureStatus() {
  new Ajax.Request(document.location, {method: 'get', evalScripts: true});
}
