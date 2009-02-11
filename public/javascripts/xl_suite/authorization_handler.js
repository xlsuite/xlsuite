
XlSuite.AuthorizationHandler = Class.create();
XlSuite.AuthorizationHandler.prototype = {
  initialize: function(root, url, options) {
    this.root = root;
    this.url = url;
    this.registeredFields = new Hash();
    this.callbacks = new Array();
    this.options = options || {};

    if (this.options.now) {
      this.registerEventHandlers();
    } else {
      Event.observe(window, "load", this.registerEventHandlers.bindAsEventListener(this));
    }
  },

  registerCallback: function(callback) {
    this.callbacks.push(callback);
  },

  registerEventHandlers: function() {
    var checkboxes = Selector.findChildElements($(this.root), ['input[type="checkbox"]']);

    for (var i = 0; i < checkboxes.length; i++) {
      var checkbox = checkboxes[i];
      Event.observe(checkbox, "click", this.onClick.bindAsEventListener(this));
    }
  },

  onClick: function(event) {
    var throbber = Event.element(event).up('div').down('.authorization_throbber');
    var options = {method: 'put', parameters: Form.serialize($(this.root))};
    if (throbber) {
      Element.show(throbber);
      options =  {method: 'put', parameters: Form.serialize($(this.root)), onComplete: function(){ Element.hide(throbber); } }
    };
    console.log("options %o", options);
    new Ajax.Request(this.url, options);
  }
};
