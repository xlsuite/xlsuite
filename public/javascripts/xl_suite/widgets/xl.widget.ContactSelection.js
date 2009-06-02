xl.widget.ContactSelection = Ext.extend(Ext.form.ComboBox,{
  displayField:'display'
  ,valueField:'id'
  ,forceSelection:true
  ,minChars:0
  ,width:350
  ,allowBlank:false

  ,initComponent:function(){
    var oThis = this;
    var partyNameAutoCompleteRecord = new Ext.data.Record.create([
      {name: 'display', mapping: 'display'}
      ,{name: 'value', mapping: 'value'}
      ,{name: 'id', mapping: 'id'}
    ]);

    var partyNameAutoCompleteReader = new Ext.data.JsonReader({totalProperty:"total", root:"collection", id:"id"}, partyNameAutoCompleteRecord);
    var partyNameAutoCompleteConnection = new Ext.data.Connection({url:"/admin/listings/auto_complete_party_field.json", method: 'get'});
    var partyNameAutoCompleteProxy = new Ext.data.HttpProxy(partyNameAutoCompleteConnection);
    var partyNameAutoCompleteStore = new Ext.data.Store({proxy: partyNameAutoCompleteProxy, reader: partyNameAutoCompleteReader});

    this.store = partyNameAutoCompleteStore;

    xl.widget.ContactSelection.superclass.initComponent.apply(this, arguments);
  }
});
// register xtype
Ext.reg('contactselection', xl.widget.ContactSelection);
