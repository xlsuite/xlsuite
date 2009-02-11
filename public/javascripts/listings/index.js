Event.observe(window, "load", function() {
  attachGalleryHandlers($$(".thumbnails img"));
});

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