/*
 * Ext JS Library 2.1
 * Copyright(c) 2006-2008, Ext JS, LLC.
 * licensing@extjs.com
 * 
 * http://extjs.com/license
 */


Ext.layout.FitLayout=Ext.extend(Ext.layout.ContainerLayout,{monitorResize:true,onLayout:function(ct,target){Ext.layout.FitLayout.superclass.onLayout.call(this,ct,target);if(!this.container.collapsed){this.setItemSize(this.activeItem||ct.items.itemAt(0),target.getStyleSize());}},setItemSize:function(item,size){if(item&&size.height>0){item.setSize(size);}}});Ext.Container.LAYOUTS['fit']=Ext.layout.FitLayout;