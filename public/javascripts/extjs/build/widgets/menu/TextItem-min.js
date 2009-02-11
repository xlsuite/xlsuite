/*
 * Ext JS Library 2.1
 * Copyright(c) 2006-2008, Ext JS, LLC.
 * licensing@extjs.com
 * 
 * http://extjs.com/license
 */


Ext.menu.TextItem=function(text){this.text=text;Ext.menu.TextItem.superclass.constructor.call(this);};Ext.extend(Ext.menu.TextItem,Ext.menu.BaseItem,{hideOnClick:false,itemCls:"x-menu-text",onRender:function(){var s=document.createElement("span");s.className=this.itemCls;s.innerHTML=this.text;this.el=s;Ext.menu.TextItem.superclass.onRender.apply(this,arguments);}});