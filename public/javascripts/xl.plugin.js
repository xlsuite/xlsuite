XLDependency = function(config) {
  var self = null;
  var actions = config.actions;
  var onEvents = [];
  
  function actBasedOnType(fn, receiver) {
    if (typeof fn == 'string') {
      if (receiver instanceof Array) {
        receiver.each(function(item) {
          eval('item.' + fn + '();');
        });
      } else {
        eval('receiver.' + fn + '();');
      } // end if (receiver instanceof Array)
      return;
    } else {
      fn(receiver, self);
    } // end if (typeof fn == 'string')
  }; // end actBasedOnType(fn, receiver)
  
  this.init = function(component) {
    self = component;
    
    // For each action...
    actions.each(function(action) {
      
      // If multiple receivers are involved...
      if (action.receivers) {
        // First convert into a Prototype Hash
        action.receivers = new Hash(action.receivers);
        
        // Then execute the before filter if present
        if (action.applyBefore) {
          action.receivers.each(function(pair) {
            var result = action.applyBefore(pair.value);
            if (result == false) return;  // Do not continue
          });
        }
        
        onEvents.push(action.on);
        
        // Set up the event handler
        self.on(action.on, function() {
          
          // Perform the test to see which receivers pass and fail
          var keyToPass = action.test(self);
          action.receivers.each(function(pair) {
            if (pair.key == keyToPass) {  // Pass
              actBasedOnType(action.pass, pair.value);
            } else {
              // if key == false, it will fail each receiver
              actBasedOnType(action.fail, pair.value);
            } // end if pair.key == key
          }); // end actions.receivers.each
          
        }); // end self.on
        
      } // end if action.receivers
      
    }); // end actions.each()
  }; // end this.init()
  
  this.destroy = function() {
    onEvents.each(function(onEvent) {
      self.un(onEvent);
    });
    
    delete this;
  }
} // end xl.plugin.Dependency

XLgenerateToggleHideShowDependency = function(receiver) {
  var dependency = new XLDependency({
    on: 'toggle',
    actions: [{
      applyBefore: function(o) { o.hide() },
      receivers: new Hash({ '0': receiver }),
      test: function(my) {
        if (receiver.isVisible())
          return false; // fail: hide it
        else
          return '0'; // pass: show it
      },
      pass: 'show',
      fail: 'hide'
    }]
  });
  return dependency;
}