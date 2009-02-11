/*
 * Ext JS Library 2.0.2
 * Copyright(c) 2006-2008, Ext JS, LLC.
 * licensing@extjs.com
 * 
 * http://extjs.com/license
 */


Ext.ReaderLayout=function(config,renderTo){var c=config||{size:{}};Ext.ReaderLayout.superclass.constructor.call(this,renderTo||document.body,{north:c.north!==false?Ext.apply({split:false,initialSize:32,titlebar:false},c.north):false,west:c.west!==false?Ext.apply({split:true,initialSize:200,minSize:175,maxSize:400,titlebar:true,collapsible:true,animate:true,margins:{left:5,right:0,bottom:5,top:5},cmargins:{left:5,right:5,bottom:5,top:5}},c.west):false,east:c.east!==false?Ext.apply({split:true,initialSize:200,minSize:175,maxSize:400,titlebar:true,collapsible:true,animate:true,margins:{left:0,right:5,bottom:5,top:5},cmargins:{left:5,right:5,bottom:5,top:5}},c.east):false,center:Ext.apply({tabPosition:'top',autoScroll:false,closeOnTab:true,titlebar:false,margins:{left:c.west!==false?0:5,right:c.east!==false?0:5,bottom:5,top:2}},c.center)});this.el.addClass('x-reader');this.beginUpdate();var inner=new Ext.BorderLayout(Ext.getBody().createChild(),{south:c.preview!==false?Ext.apply({split:true,initialSize:200,minSize:100,autoScroll:true,collapsible:true,titlebar:true,cmargins:{top:5,left:0,right:0,bottom:0}},c.preview):false,center:Ext.apply({autoScroll:false,titlebar:false,minHeight:200},c.listView)});this.add('center',new Ext.NestedLayoutPanel(inner,Ext.apply({title:c.mainTitle||'',tabTip:''},c.innerPanelCfg)));this.endUpdate();this.regions.preview=inner.getRegion('south');this.regions.listView=inner.getRegion('center');};Ext.extend(Ext.ReaderLayout,Ext.BorderLayout);