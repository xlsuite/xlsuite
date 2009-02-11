/*
 * Ext JS Library 2.1
 * Copyright(c) 2006-2008, Ext JS, LLC.
 * licensing@extjs.com
 * 
 * http://extjs.com/license
 */


Ext.form.Radio=Ext.extend(Ext.form.Checkbox,{inputType:'radio',markInvalid:Ext.emptyFn,clearInvalid:Ext.emptyFn,getGroupValue:function(){var p=this.el.up('form')||Ext.getBody();var c=p.child('input[name='+this.el.dom.name+']:checked',true);return c?c.value:null;},onClick:function(){if(this.el.dom.checked!=this.checked){var p=this.el.up('form')||Ext.getBody();var els=p.select('input[name='+this.el.dom.name+']');els.each(function(el){if(el.dom.id==this.id){this.setValue(true);}else{Ext.getCmp(el.dom.id).setValue(false);}},this);}},setValue:function(v){if(typeof v=='boolean'){Ext.form.Radio.superclass.setValue.call(this,v);}else{var r=this.el.up('form').child('input[name='+this.el.dom.name+'][value='+v+']',true);if(r){r.checked=true;};}}});Ext.reg('radio',Ext.form.Radio);