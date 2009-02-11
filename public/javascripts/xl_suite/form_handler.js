//XlSuite FormHandler
//Options: 
//  now: boolean           - true to register event handlers
//  defaultValue: string   - default value to display when the field is blank
//  registerNewObject: boolean - true to register new object to event handlers


var XlSuite = new Object();

XlSuite.FormHandler = Class.create();
XlSuite.FormHandler.prototype = {
  initialize: function(root, options) {
    this.root = root;
    this.registeredFields = new Hash();
    this.callbacks = new Array();
    this.options = options || {};

    if (this.options.now) {
      this.registerEventHandlers();
    } else {
      Event.observe(window, "load", this.registerEventHandlers.bindAsEventListener(this));
    }

    Ajax.Responders.register({
      onComplete: this.registerEventHandlers.bindAsEventListener(this)
    });
  },

  registerCallback: function(callback) {
    this.callbacks.push(callback);
  },

  registerEventHandlers: function() {
    var editors = Selector.findChildElements($(this.root), ["input.subtleField", "select.subtleField", "textarea.subtleField"]);

    for (var i = 0; i < editors.length; i++) {
      var field = editors[i];
      
      var condition = false;
      if (this.registeredFields[field.id] != field && field.id.substring(0, 4) != "new_") {
        condition = true;
      }
      if (this.options.registerNewObject) {
        if (this.registeredFields[field.id] != field){
          condition = true;
        }
      }
        
      if (condition) {
        var showLine = this.findElementWithSuffix(field, "show");
        if (showLine) {
          Event.observe(showLine, "click", this.onClick.bindAsEventListener(this));
          Event.observe(showLine, "focus", this.onClick.bindAsEventListener(this));
          if( showLine.innerHTML.blank() && this.options.defaultValue) showLine.innerHTML = this.options.defaultValue;
        }

        Event.observe(field, "focus", this.onFocus.bindAsEventListener(this));
        Event.observe(field, "keypress", this.onKeypress.bindAsEventListener(this));
        Event.observe(field, "blur", this.persist.bindAsEventListener(this, field));
        field.persist = this.persist.bindAsEventListener(this, field);
        this.registeredFields[field.id] = field;
      }
    }
  },

  findElementWithSuffix: function(element, suffix) {
    var parts = element.id.split("_");
    var newName = "";
    for (var i = 0; i < parts.length - 1; i++) {
      newName += parts[i];
      newName += "_";
    }

    return $(newName + suffix);
  },

  showIndicator: function(element) {
    var throbber = this.findElementWithSuffix(element, "indicator");
    Element.show(throbber);
  },

  hideIndicator: function(element) {
    var throbber = this.findElementWithSuffix(element, "indicator");
    Element.hide(throbber);
  },

  findField: function(editor) {
    var field = editor.down("input");
    if (null == field) field = editor.down("select");
    if (null == field) field = editor.down("textarea");
    return field;
  },

  activate: function(editor) {
    var field = this.findField(editor);

    field.activate();
    field.setAttribute("oldvalue", field.value);
    if (field.getAttribute("data_field") != null) {
      field = $(field.getAttribute("data_field"));
      field.setAttribute("oldvalue", field.value);
    }
    return field;
  },

  onSaved: function(field, transport, json, copyText) {
    var show = this.findElementWithSuffix(field, "show");
    if (copyText) show.innerHTML = transport.responseText;

    //if the field is blank, show the default value if specified in the options
    if( show.innerHTML.blank() && this.options.defaultValue) show.innerHTML = this.options.defaultValue;
        
    this.hideIndicator(show);
    new Effect.Highlight(show);

    this.invokeCallbacks();
  },

  invokeCallbacks: function() {
    this.callbacks.each(function(callback) { callback(); });
  },
    
  persist: function(event, field) {
    var editContainer = this.findElementWithSuffix(field, "edit");
    var showContainer = this.findElementWithSuffix(field, "show");

    // Early abort if the editor is not shown
    if (!editContainer.visible() && field.getAttribute("persist") != "true") return;

    Element.show(showContainer);
    Element.hide(editContainer);

    var dataField = null;
    if (field.getAttribute("data_field") != null) {
      dataField = $(field.getAttribute("data_field"));
    }

    if (field.value != field.getAttribute("oldvalue")) {
      showContainer.innerHTML = field.value;
      showContainer.removeClassName("blank");
      var url = editContainer.getAttribute("url") || editContainer.up("form").getAttribute("action");

      showContainer.innerHTML = field.value;

      var params = {};
      params[field.name] = field.value;
      if (dataField != null) params[dataField.name] = dataField.value;

      var ajaxOptions = {};
      ajaxOptions["method"] = "put";
      ajaxOptions["parameters"] = params;
      if (url.match(/\.txt$/)) {
        ajaxOptions["evalScripts"] = false;
      } else {
        ajaxOptions["evalScripts"] = true;
      }

      var self = this;
      ajaxOptions["onComplete"] = function(transport, json) { self.onSaved(field, transport, json, !ajaxOptions["evalScripts"]) };
      new Ajax.Request(url, ajaxOptions);
      this.showIndicator(field);
    }
  },

  onKeypress: function(event) {
    var field = Event.element(event);

    switch (event.keyCode) {
      case Event.KEY_RETURN:
        if (field.tagName.toLowerCase() == "textarea") return;
        Event.stop(event);
        $("elsewhere").focus(); // Generate blur event for current field
        break;

      case Event.KEY_ESC:
        Element.hide(this.findElementWithSuffix(field, "edit"));
        Element.show(this.findElementWithSuffix(field, "show"));

        Event.stop(event);
        break;
    }
  },

  onClick: function(event) {
    var element = Event.element(event);
    this.showEditor(element);
  },

  showEditor: function(element) {
    element = $(element);
    while (element && !element.hasClassName("show")) {
      element = element.parentNode;
    }

    if (element == null) return;
    var editor = this.findElementWithSuffix(element, "edit");
    Element.hide(element)
    Element.show(editor);
    this.activate(editor);
  },

  onFocus: function(event) {
    var element = Event.element(event);
    var editor = this.findElementWithSuffix(element, "edit");
    this.activate(editor);
  }
};
