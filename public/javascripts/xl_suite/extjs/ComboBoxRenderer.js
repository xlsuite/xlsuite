Ext.namespace("Ext.ux");
Ext.ux.ComboBoxRenderer = function(combo) {
  return function(value) {
    var idx = combo.store.find(combo.valueField, value);
    var rec = combo.store.getAt(idx);
    return (rec == null ? '' : rec.get(combo.displayField) );
  };
}