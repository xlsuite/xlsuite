Event.observe(window, "load", function() {
  var dtChildren = new Selector("dt");
  var ddChildren = new Selector("dd");

  $$("dt").each(function(dt) {
    var root = dt.up("dl");
    var dd = $(dt.id + "_body");
    if (dd == undefined) return;
    var radio = dd.down("input[type=radio]");
    if (radio == undefined) return;

    function selectTemplate() {
      [dtChildren.findElements(root), ddChildren.findElements(root)].flatten().each(function(e) { e.removeClassName("selected") });
      dt.addClassName("selected");
      dd.addClassName("selected");
      radio.checked = true;
    }

    radio.observe("click", selectTemplate);
    dt.observe("click", selectTemplate);
    dd.observe("click", selectTemplate);
  });

  $$("dt").each(function(dt) {
    var root = dt.up("dl");
    var dd = $(dt.id + "_body");
    if (dd == undefined) return;
    var check = dd.down("input[type=checkbox]");
    if (check == undefined) return;

    function selectTemplate() {
      if (check.checked) {
        dt.removeClassName("selected");
        dd.removeClassName("selected");
        check.checked = false;
      } else {
        dt.addClassName("selected");
        dd.addClassName("selected");
        check.checked = true;
      }
    }

    check.observe("click", selectTemplate);
    dt.observe("click", selectTemplate);
    dd.observe("click", selectTemplate);
  });
});
