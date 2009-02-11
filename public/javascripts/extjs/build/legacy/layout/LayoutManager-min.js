/*
 * Ext JS Library 2.0.2
 * Copyright(c) 2006-2008, Ext JS, LLC.
 * licensing@extjs.com
 * 
 * http://extjs.com/license
 */


Ext.LayoutManager=function(container,config){Ext.LayoutManager.superclass.constructor.call(this);this.el=Ext.get(container);if(this.el.dom==document.body&&Ext.isIE&&!config.allowScroll){document.body.scroll="no";}else if(this.el.dom!=document.body&&this.el.getStyle('position')=='static'){this.el.position('relative');}
this.id=this.el.id;this.el.addClass("x-layout-container");this.monitorWindowResize=true;this.regions={};this.addEvents({"layout":true,"regionresized":true,"regioncollapsed":true,"regionexpanded":true});this.updating=false;Ext.EventManager.onWindowResize(this.onWindowResize,this,true);};Ext.extend(Ext.LayoutManager,Ext.util.Observable,{isUpdating:function(){return this.updating;},beginUpdate:function(){this.updating=true;},endUpdate:function(noLayout){this.updating=false;if(!noLayout){this.layout();}},layout:function(){},onRegionResized:function(region,newSize){this.fireEvent("regionresized",region,newSize);this.layout();},onRegionCollapsed:function(region){this.fireEvent("regioncollapsed",region);},onRegionExpanded:function(region){this.fireEvent("regionexpanded",region);},getViewSize:function(){var size;if(this.el.dom!=document.body){size=this.el.getSize();}else{size={width:Ext.lib.Dom.getViewWidth(),height:Ext.lib.Dom.getViewHeight()};}
size.width-=this.el.getBorderWidth("lr")-this.el.getPadding("lr");size.height-=this.el.getBorderWidth("tb")-this.el.getPadding("tb");return size;},getEl:function(){return this.el;},getRegion:function(target){return this.regions[target.toLowerCase()];},onWindowResize:function(){if(this.monitorWindowResize){this.layout();}}});