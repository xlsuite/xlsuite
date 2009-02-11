XLManager = function(config) {  
  // private
  var config = config || {};
  var base = config.base || Ext.id();
  var lastId = config.start || -1;
  var objects = new Hash();
  
  // privelaged
  this.getLastIdNumber = function() {
    return lastId;
  };
  
  this.id = function() {
    return base + '.' + lastId;
  };
  
  this.nextId = function() {
    lastId++;
    return this.id();
  };
  
  this.previousId = function(n) {
    return base + '.' + (lastId - n);
  };
  
  this.lastId = function() {
    return this.previousId(1);
  };
  
  // Very important
  // Adds an object to the internal Hash with
  // the next id in line.
  this.add = function(object, id) {
    var id = id || this.nextId();
    objects.set(id, object);
  };
  
  this.get = function(id) {
    return objects.get(id);
  };
  
  this.getWithIdNumber = function(n) {
    return objects.get(base + '.' + n);
  };
  
  this.remove = function(id) {
    return objects.unset(id);
  };
  
  this.getPrevious = function(n) {
    return objects.get(this.previousId(n));
  };
  
  // Just a proxy for objects.each
  this.each = function(fn) {
    return objects.each(fn);
  }
  
  // I would like to implement this to use
  // id and object instead of pair
  this.collect = function(fn) {
    return objects.collect(fn);
  }
  
  this.nextIdWithBase = function(base, sep) {
    lastId++;
    var sep = sep || '.';
    return base + sep + this.getLastIdNumber();
  }
}

/*
// Define global Manager object
xl.manager.Manager._manager = new xl.manager.Manager();

// Shortcut Function
xl.manager.Manager.id = function(base) {
  var base = base || 'managed';
  return xl.manager.Manager._manager.nextIdWithBase(base);
}
*/