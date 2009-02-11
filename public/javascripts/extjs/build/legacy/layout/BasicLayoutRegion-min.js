/*
 * Ext JS Library 2.0.2
 * Copyright(c) 2006-2008, Ext JS, LLC.
 * licensing@extjs.com
 * 
 * http://extjs.com/license
 */


Ext.BasicLayoutRegion=function(mgr,config,pos,skipConfig){this.mgr=mgr;this.position=pos;this.events={"beforeremove":true,"invalidated":true,"visibilitychange":true,"paneladded":true,"panelremoved":true,"collapsed":true,"expanded":true,"slideshow":true,"slidehide":true,"panelactivated":true,"resized":true};this.panels=new Ext.util.MixedCollection();this.panels.getKey=this.getPanelId.createDelegate(this);this.box=null;this.activePanel=null;if(skipConfig!==true){this.applyConfig(config);}};Ext.extend(Ext.BasicLayoutRegion,Ext.util.Observable,{getPanelId:function(p){return p.getId();},applyConfig:function(config){this.margins=config.margins||this.margins||{top:0,left:0,right:0,bottom:0};this.config=config;},resizeTo:function(newSize){var el=this.el?this.el:(this.activePanel?this.activePanel.getEl():null);if(el){switch(this.position){case"east":case"west":el.setWidth(newSize);this.fireEvent("resized",this,newSize);break;case"north":case"south":el.setHeight(newSize);this.fireEvent("resized",this,newSize);break;}}},getBox:function(){return this.activePanel?this.activePanel.getEl().getBox(false,true):null;},getMargins:function(){return this.margins;},updateBox:function(box){this.box=box;var el=this.activePanel.getEl();el.dom.style.left=box.x+"px";el.dom.style.top=box.y+"px";this.activePanel.setSize(box.width,box.height);},getEl:function(){return this.activePanel;},isVisible:function(){return this.activePanel?true:false;},setActivePanel:function(panel){panel=this.getPanel(panel);if(this.activePanel&&this.activePanel!=panel){this.activePanel.setActiveState(false);this.activePanel.getEl().setLeftTop(-10000,-10000);}
this.activePanel=panel;panel.setActiveState(true);if(this.box){panel.setSize(this.box.width,this.box.height);}
this.fireEvent("panelactivated",this,panel);this.fireEvent("invalidated");},showPanel:function(panel){if(panel=this.getPanel(panel)){this.setActivePanel(panel);}
return panel;},getActivePanel:function(){return this.activePanel;},add:function(panel){if(arguments.length>1){for(var i=0,len=arguments.length;i<len;i++){this.add(arguments[i]);}
return null;}
if(this.hasPanel(panel)){this.showPanel(panel);return panel;}
var el=panel.getEl();if(el.dom.parentNode!=this.mgr.el.dom){this.mgr.el.dom.appendChild(el.dom);}
if(panel.setRegion){panel.setRegion(this);}
this.panels.add(panel);el.setStyle("position","absolute");if(!panel.background){this.setActivePanel(panel);if(this.config.initialSize&&this.panels.getCount()==1){this.resizeTo(this.config.initialSize);}}
this.fireEvent("paneladded",this,panel);return panel;},hasPanel:function(panel){if(typeof panel=="object"){panel=panel.getId();}
return this.getPanel(panel)?true:false;},remove:function(panel,preservePanel){panel=this.getPanel(panel);if(!panel){return null;}
var e={};this.fireEvent("beforeremove",this,panel,e);if(e.cancel===true){return null;}
var panelId=panel.getId();this.panels.removeKey(panelId);return panel;},getPanel:function(id){if(typeof id=="object"){return id;}
return this.panels.get(id);},getPosition:function(){return this.position;}});