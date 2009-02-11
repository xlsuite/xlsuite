Event.observe(window, "load", function() {
  $$("input[type=submit]").each(function(elem) {
    Event.observe(elem, "click", function(e) {
      var form = elem.up("form");
      var url = form.getAttribute("action");
      var params = Form.serialize(form);
      if(elem.value.match(/close/i))
        params = params.gsub(/commit=\w+/, "commit=Close");

      $$("img.save_indicator").each(function(e){
        e.show(); 
      });
      new Ajax.Request(url, {
        method: "post", 
        parameters: params,
        onComplete: function() {
            $$("img.save_indicator").each(function(e){
              e.hide(); 
            });
          }
      });

      Event.stop(e);
    });
  });
});
