/*
 * Ext JS Library 2.0.2
 * Copyright(c) 2006-2008, Ext JS, LLC.
 * licensing@extjs.com
 * 
 * http://extjs.com/license
 */


Ext.JsonView=function(container,tpl,config){Ext.JsonView.superclass.constructor.call(this,container,tpl,config);var um=this.el.getUpdater();um.setRenderer(this);um.on("update",this.onLoad,this);um.on("failure",this.onLoadException,this);this.addEvents({'beforerender':true,'load':true,'loadexception':true});};Ext.extend(Ext.JsonView,Ext.View,{jsonRoot:"",refresh:function(){this.clearSelections();this.el.update("");var html=[];var o=this.jsonData;if(o&&o.length>0){for(var i=0,len=o.length;i<len;i++){var data=this.prepareData(o[i],i,o);html[html.length]=this.tpl.apply(data);}}else{html.push(this.emptyText);}
this.el.update(html.join(""));this.nodes=this.el.dom.childNodes;this.updateIndexes(0);},load:function(){var um=this.el.getUpdater();um.update.apply(um,arguments);},render:function(el,response){this.clearSelections();this.el.update("");var o;try{o=Ext.util.JSON.decode(response.responseText);if(this.jsonRoot){o=eval("o."+this.jsonRoot);}}catch(e){}
this.jsonData=o;this.beforeRender();this.refresh();},getCount:function(){return this.jsonData?this.jsonData.length:0;},getNodeData:function(node){if(Ext.isArray(node)){var data=[];for(var i=0,len=node.length;i<len;i++){data.push(this.getNodeData(node[i]));}
return data;}
return this.jsonData[this.indexOf(node)]||null;},beforeRender:function(){this.snapshot=this.jsonData;if(this.sortInfo){this.sort.apply(this,this.sortInfo);}
this.fireEvent("beforerender",this,this.jsonData);},onLoad:function(el,o){this.fireEvent("load",this,this.jsonData,o);},onLoadException:function(el,o){this.fireEvent("loadexception",this,o);},filter:function(property,value){if(this.jsonData){var data=[];var ss=this.snapshot;if(typeof value=="string"){var vlen=value.length;if(vlen==0){this.clearFilter();return;}
value=value.toLowerCase();for(var i=0,len=ss.length;i<len;i++){var o=ss[i];if(o[property].substr(0,vlen).toLowerCase()==value){data.push(o);}}}else if(value.exec){for(var i=0,len=ss.length;i<len;i++){var o=ss[i];if(value.test(o[property])){data.push(o);}}}else{return;}
this.jsonData=data;this.refresh();}},filterBy:function(fn,scope){if(this.jsonData){var data=[];var ss=this.snapshot;for(var i=0,len=ss.length;i<len;i++){var o=ss[i];if(fn.call(scope||this,o)){data.push(o);}}
this.jsonData=data;this.refresh();}},clearFilter:function(){if(this.snapshot&&this.jsonData!=this.snapshot){this.jsonData=this.snapshot;this.refresh();}},sort:function(property,dir,sortType){this.sortInfo=Array.prototype.slice.call(arguments,0);if(this.jsonData){var p=property;var dsc=dir&&dir.toLowerCase()=="desc";var f=function(o1,o2){var v1=sortType?sortType(o1[p]):o1[p];var v2=sortType?sortType(o2[p]):o2[p];;if(v1<v2){return dsc?+1:-1;}else if(v1>v2){return dsc?-1:+1;}else{return 0;}};this.jsonData.sort(f);this.refresh();if(this.jsonData!=this.snapshot){this.snapshot.sort(f);}}}});