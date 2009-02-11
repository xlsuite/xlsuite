/*
 * Ext JS Library 2.0.2
 * Copyright(c) 2006-2008, Ext JS, LLC.
 * licensing@extjs.com
 * 
 * http://extjs.com/license
 */


Ext.BorderLayout=function(container,config){config=config||{};Ext.BorderLayout.superclass.constructor.call(this,container,config);this.factory=config.factory||Ext.BorderLayout.RegionFactory;for(var i=0,len=this.factory.validRegions.length;i<len;i++){var target=this.factory.validRegions[i];if(config[target]){this.addRegion(target,config[target]);}}};Ext.extend(Ext.BorderLayout,Ext.LayoutManager,{addRegion:function(target,config){if(!this.regions[target]){var r=this.factory.create(target,this,config);this.bindRegion(target,r);}
return this.regions[target];},bindRegion:function(name,r){this.regions[name]=r;r.on("visibilitychange",this.layout,this);r.on("paneladded",this.layout,this);r.on("panelremoved",this.layout,this);r.on("invalidated",this.layout,this);r.on("resized",this.onRegionResized,this);r.on("collapsed",this.onRegionCollapsed,this);r.on("expanded",this.onRegionExpanded,this);},layout:function(){if(this.updating)return;var size=this.getViewSize();var w=size.width,h=size.height;var centerW=w,centerH=h,centerY=0,centerX=0;var rs=this.regions;var n=rs["north"],s=rs["south"],west=rs["west"],e=rs["east"],c=rs["center"];if(n&&n.isVisible()){var b=n.getBox();var m=n.getMargins();b.width=w-(m.left+m.right);b.x=m.left;b.y=m.top;centerY=b.height+b.y+m.bottom;centerH-=centerY;n.updateBox(this.safeBox(b));}
if(s&&s.isVisible()){var b=s.getBox();var m=s.getMargins();b.width=w-(m.left+m.right);b.x=m.left;var totalHeight=(b.height+m.top+m.bottom);b.y=h-totalHeight+m.top;centerH-=totalHeight;s.updateBox(this.safeBox(b));}
if(west&&west.isVisible()){var b=west.getBox();var m=west.getMargins();b.height=centerH-(m.top+m.bottom);b.x=m.left;b.y=centerY+m.top;var totalWidth=(b.width+m.left+m.right);centerX+=totalWidth;centerW-=totalWidth;west.updateBox(this.safeBox(b));}
if(e&&e.isVisible()){var b=e.getBox();var m=e.getMargins();b.height=centerH-(m.top+m.bottom);var totalWidth=(b.width+m.left+m.right);b.x=w-totalWidth+m.left;b.y=centerY+m.top;centerW-=totalWidth;e.updateBox(this.safeBox(b));}
if(c){var m=c.getMargins();var centerBox={x:centerX+m.left,y:centerY+m.top,width:centerW-(m.left+m.right),height:centerH-(m.top+m.bottom)};c.updateBox(this.safeBox(centerBox));}
this.el.repaint();this.fireEvent("layout",this);},safeBox:function(box){box.width=Math.max(0,box.width);box.height=Math.max(0,box.height);return box;},add:function(target,panel){target=target.toLowerCase();return this.regions[target].add(panel);},remove:function(target,panel){target=target.toLowerCase();return this.regions[target].remove(panel);},findPanel:function(panelId){var rs=this.regions;for(var target in rs){if(typeof rs[target]!="function"){var p=rs[target].getPanel(panelId);if(p){return p;}}}
return null;},showPanel:function(panelId){var rs=this.regions;for(var target in rs){var r=rs[target];if(typeof r!="function"){if(r.hasPanel(panelId)){return r.showPanel(panelId);}}}
return null;},restoreState:function(provider){if(!provider){provider=Ext.state.Manager;}
var sm=new Ext.LayoutStateManager();sm.init(this,provider);},batchAdd:function(regions){this.beginUpdate();for(var rname in regions){var lr=this.regions[rname];if(lr){this.addTypedPanels(lr,regions[rname]);}}
this.endUpdate();},addTypedPanels:function(lr,ps){if(typeof ps=='string'){lr.add(new Ext.ContentPanel(ps));}
else if(Ext.isArray(ps)){for(var i=0,len=ps.length;i<len;i++){this.addTypedPanels(lr,ps[i]);}}
else if(!ps.events){var el=ps.el;delete ps.el;lr.add(new Ext.ContentPanel(el||Ext.id(),ps));}
else{lr.add(ps);}}});Ext.BorderLayout.create=function(config,targetEl){var layout=new Ext.BorderLayout(targetEl||document.body,config);layout.beginUpdate();var regions=Ext.BorderLayout.RegionFactory.validRegions;for(var j=0,jlen=regions.length;j<jlen;j++){var lr=regions[j];if(layout.regions[lr]&&config[lr].panels){var r=layout.regions[lr];var ps=config[lr].panels;layout.addTypedPanels(r,ps);}}
layout.endUpdate();return layout;};Ext.BorderLayout.RegionFactory={validRegions:["north","south","east","west","center"],create:function(target,mgr,config){target=target.toLowerCase();if(config.lightweight||config.basic){return new Ext.BasicLayoutRegion(mgr,config,target);}
switch(target){case"north":return new Ext.NorthLayoutRegion(mgr,config);case"south":return new Ext.SouthLayoutRegion(mgr,config);case"east":return new Ext.EastLayoutRegion(mgr,config);case"west":return new Ext.WestLayoutRegion(mgr,config);case"center":return new Ext.CenterLayoutRegion(mgr,config);}
throw'Layout region "'+target+'" not supported.';}};