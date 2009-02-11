Event.observe(window, "load", function() {
  setInterval(updateProgressBar, 10000);

  attachGalleryHandlers($$(".thumbnails img"));

  $$("a.show_raw_results", "a.hide_raw_results").each(function(e) {
    Event.observe(e, "click", toggleRawResults.bindAsEventListener());
  });

  $$("form[id^=listing_]").each(function(form) {
    new XlSuite.FormHandler(form.id, {now: true});
  });
});

function updateProgressBar() {
  $$("div.progress_bar").each(function(e) {
    var url = e.getAttribute("progress_url");
    if (url == null || url.toString() == "") return;

    if (e.next(".status").innerHTML.match(/\bcomplete(?:\b|d)/i)) {
      var root = e.up(".gallery");
      e.removeAttribute("progress_url");

      new Ajax.Request(e.getAttribute("photos_url"), {method: "get", evalScripts: true,
          onComplete: function() {
            var images = $$("#" + root.id + " .thumbnails img");
            attachGalleryHandlers(images);
          }});
    } else {
      new Ajax.Request(url, {method: "get", evalScripts: true});
    }
  });
}

function attachGalleryHandlers(images) {
  images.each(function(img) {
    Event.observe(img, "click", changeSelectedGalleryImage.bindAsEventListener());
  });
}

function changeSelectedGalleryImage(e) {
  var img = Event.element(e);
  var root = img.up(".gallery");
  var main_img = root.down(".main img");

  root.getElementsByClassName("selected").each(function(el) {el.removeClassName("selected")});
  img.up("*").addClassName("selected");
  main_img.src = img.getAttribute("fullsize");

  Event.stop(e);
}

function toggleRawResults(e) {
  var anchor = Event.element(e);
  if (anchor.tagName.toLowerCase() != "a") anchor = anchor.up("a");

  var target = anchor.id.sub(/(?:show|hide)_raw$/, "raw_results");
  if ($(target)) Element.toggle(target);

  Event.stop(e);
}
