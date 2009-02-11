XlSuiteOtherNameHandler = Class.create();
XlSuiteOtherNameHandler.prototype = {
  initialize: function() {
    this.observed = {};
    this.registerEventHandlers();

    Ajax.Responders.register({
      onComplete: this.registerEventHandlers.bindAsEventListener(this)
    });
  },

  registerEventHandlers: function() {
    var self = this;
    $$("select.subtleField").each(function(element) {
      if (element.name.match(/name/)
          && (null == self.observed[element.name] || self.observed[element.name] != element)) {
        Event.observe(element, "change", self.otherNameHandler.bindAsEventListener(self));
        self.observed[element.name] = element;
      }
    });
  },

  otherNameHandler: function(event) {
    var element = Event.element(event);
    if ("Other..." == element.options[element.selectedIndex].value) {
      var newName = prompt("New Name", "");
      if (null == newName || newName == "") return;
      var newOption = document.createElement("option");
      newOption.value = newName;
      newOption.innerHTML = newName;
      element.add(newOption, null);
  
      for (var i = element.length - 1; i >= 0; i--) {
        if (element.options[i].value == newName) {
          element.selectedIndex = i;
          break;
        }
      }
  
      element.persist();
    }
  }
};

Event.observe(window, "load", function() {
  var nameHandler = new XlSuiteOtherNameHandler();
});
