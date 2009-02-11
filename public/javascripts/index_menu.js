IndexMenu = Class.create();

IndexMenu.prototype = {
  initialize: function(selectionId, formId) {
    Event.observe(window, "load", function() {
      if ($(selectionId) && $(formId)) {
        this.num_of_checked_items = 0;
        this.selectionId = selectionId;
        this.formId = formId;
        this.clearAllCheckBoxesInsideForm();
        this.disableAllSelectionOptions();
        this.registerOnChangeEventHandler();
        this.registerOnClickEventHandler();
        return this;
      } else {
        return false;
      }
    }.bindAsEventListener(this));
  },
  
  registerOnChangeEventHandler: function() {
    var selectionElement = $(this.selectionId);
    Event.observe(selectionElement, "change", this.selectionOnChange.bindAsEventListener(this));
  },
  
  registerOnClickEventHandler: function() {
    var checkBoxes = $$("#"+this.formId+" input[type='checkbox']")
    for (var i=0; i < checkBoxes.length; i++) {
      Event.observe(checkBoxes[i], "click", this.checkBoxOnClick.bindAsEventListener(this, checkBoxes[i]));
    };
  },
  
  selectionOnChange: function() {
    var selectionElement = $(this.selectionId);
    var formElement = $(this.formId);
    var optionSelected = selectionElement.options[selectionElement.selectedIndex];
    
    var path = optionSelected.readAttribute("path");
    var xhr = optionSelected.readAttribute("xhr");
    var confirmationMessage = optionSelected.readAttribute("confirm");
    var windowId = optionSelected.readAttribute("window");
    
    if (!path) { return false; }
    
    if (windowId) {
      var originalElement = $(windowId);
      var okLabel = optionSelected.readAttribute("okLabel") || "Submit";
      var cancelLabel = optionSelected.readAttribute("cancelLabel") || "Cancel";
      
      var windowClassName = optionSelected.readAttribute("windowClass") || "";
      windowClassName += " alphacube";

      var windowHeight = originalElement.readAttribute("height") || optionSelected.readAttribute("windowHeight") || 100;
      var windowWidth = originalElement.readAttribute("width") || optionSelected.readAttribute("windowWidth") || 200;      

      var windowTitle  = optionSelected.readAttribute("windowTitle");
      var windowContent = '<div class="window_notifications" style="display: none" id="' +windowId+ '_windowNotifications"></div>'; 
      windowContent += "<div class='content_window'>" + this.removeIdsFromHtml(originalElement.innerHTML) + "</div>";
      
      windowContent += "<div class=\"okButton_window\">";
      windowContent += "<a onclick=\"executeWindowSubmit('" +path+ "', '" +windowId+ "', '" +xhr+ "'); return false;\" href=\"#\">" +okLabel+ "</a>";
      windowContent += '<img width="16" height="16" style="display: none;" src="/images/throbber.gif" id="listMenu_throbber" class="throbber" alt="AJAX request in progress"/>';
      windowContent += "</div>";
      windowContent += "<div class=\"cancelButton_window\"><a onclick=\"Windows.close('" + windowId+"_window" + "'); return false;\" href=\"#\">" +cancelLabel+ "</a></div>";

      var windowElement = new Window(windowId+"_window", 
        {
          className: windowClassName, 
          title: windowTitle,
          destroyOnClose: true,
          minimizable: false, maximizable: false, closable: false, 
          opacity: 1, 
          
          width: windowWidth, height: windowHeight,
          onDestroy: function() { $(windowId).hide(); selectionElement.selectedIndex = 0; }
        });
      
      windowElement.setHTMLContent(windowContent);
      windowElement.showCenter();
    }
    else if (confirmationMessage) {
      var state = window.confirm(confirmationMessage)
      if (state) {
        if (xhr == 'yes') {
          var selectionMenuThrobber = $(this.selectionId+"_throbber") || $(this.selectionId+"_indicator");
          if (selectionMenuThrobber) {selectionMenuThrobber.show()};
          new Ajax.Request(path, { 
            parameters: Form.serialize(formElement.id), asynchronous:true, evalScripts:true, 
            onComplete: function() { 
              if (selectionMenuThrobber) {selectionMenuThrobber.hide()}; 
              selectionElement.selectedIndex = 0;
            }
          });
        }
        else {
          formElement.action = path;
          formElement.submit();
        }
      }
      else {
        selectionElement.selectedIndex = 0;
      }
    }
    this.updateSelectionMenu(); 
  },
  
  checkBoxOnClick: function(event, checkbox) {
    if (checkbox.checked) {
      this.num_of_checked_items++;
    }
    else {
      if (this.num_of_checked_items > 0) {
        this.num_of_checked_items--;
      }
    }
    this.updateSelectionMenu();
  },
  
  updateSelectionMenu: function() {
    var selectionElement = $(this.selectionId);
    if (!selectionElement) return;
    for (var i=0; i<selectionElement.length; i++) {
      if (selectionElement.options[i].getAttribute("path") != null) {
        if (selectionElement.options[i].getAttribute("path") != "" && this.num_of_checked_items > 0) {
          selectionElement.options[i].disabled = false;
        }
        else {
          selectionElement.options[i].disabled = true;
        }
      }
      else {
        selectionElement.options[i].disabled = true;
      }
    }
  },
  
  disableAllSelectionOptions: function() {
    var selectionElement = $(this.selectionId);
    if (!selectionElement) return;
    selectionElement.selectedIndex = 0;
    for (var i=0; i<selectionElement.length; i++) {
      selectionElement.options[i].disabled = true;
    }
  },
  
  removeIdsFromHtml: function(string) {
    var result = string.replace(/\sid="[^\s]+"\s/i, ' id="fake_id" ');
    return result;
  },  

  
  clearAllCheckBoxesInsideForm: function() {
    var formElement = $(this.formId);
    if (!formElement) return;
    formElement.getElementsBySelector('input[type="checkbox"]').each(
      function(e) { e.checked = false; }
    )
  }
}

function executeWindowSubmit(path, windowId, xhr) {
  var allInputBlanks = updateInputFieldsFromCloneToOriginalDiv(windowId + "_window");
  var formElement = $(windowId).up('form');
  
  if (!allInputBlanks) {
    $(windowId + '_windowNotifications').hide();
    $("listMenu_throbber").show();
    if (xhr == "yes") {
      new Ajax.Request(path, 
        {
          parameters: Form.serialize(formElement.id),
          asynchronous:true, evalScripts:true,
          onComplete: function() {$("listMenu_throbber").hide(); Windows.close(windowId + "_window");} 
        }
      );
    }
    else {
      formElement.action = path;
      formElement.submit();
    }
  }
  else {
    var windowNotificationElement = $(windowId + '_windowNotifications');
    windowNotificationElement.innerHTML = "Please fill in all input field(s)";
    windowNotificationElement.show();
  }
}

function updateInputFieldsFromCloneToOriginalDiv(cloneId) {
  var allInputBlanks = true;
  var inputFields = $$('#' + cloneId +' input');
    
  inputFields.each( 
    function(e) {
      $(e.getAttribute("name")).value = e.value;
      if (e.value != "") {
        allInputBlanks = false;
      }
    }
  );
  
  $$('#' + cloneId + ' select').each(
    function(e) {
      $(e.getAttribute("name")).selectedIndex = e.selectedIndex;
    }
  )
  
  if (inputFields.length == 0) { return false; }

  return allInputBlanks;
}