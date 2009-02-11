/*
 * Ext JS Library 2.0.2
 * Copyright(c) 2006-2008, Ext JS, LLC.
 * licensing@extjs.com
 * 
 * http://extjs.com/license
 */


Ext.View=function(container,tpl,config){this.el=Ext.get(container);if(typeof tpl=="string"){tpl=new Ext.Template(tpl);}
tpl.compile();this.tpl=tpl;Ext.apply(this,config);this.addEvents({"beforeclick":true,"click":true,"dblclick":true,"contextmenu":true,"selectionchange":true,"beforeselect":true});this.el.on({"click":this.onClick,"dblclick":this.onDblClick,"contextmenu":this.onContextMenu,scope:this});this.selections=[];this.nodes=[];this.cmp=new Ext.CompositeElementLite([]);if(this.store){this.setStore(this.store,true);}
Ext.View.superclass.constructor.call(this);};Ext.extend(Ext.View,Ext.util.Observable,{selectedClass:"x-view-selected",emptyText:"",getEl:function(){return this.el;},refresh:function(){var t=this.tpl;this.clearSelections();this.el.update("");var html=[];var records=this.store.getRange();if(records.length<1){this.el.update(this.emptyText);return;}
for(var i=0,len=records.length;i<len;i++){var data=this.prepareData(records[i].data,i,records[i]);html[html.length]=t.apply(data);}
this.el.update(html.join(""));this.nodes=this.el.dom.childNodes;this.updateIndexes(0);},prepareData:function(data){return data;},onUpdate:function(ds,record){this.clearSelections();var index=this.store.indexOf(record);var n=this.nodes[index];this.tpl.insertBefore(n,this.prepareData(record.data));n.parentNode.removeChild(n);this.updateIndexes(index,index);},onAdd:function(ds,records,index){this.clearSelections();if(this.nodes.length==0){this.refresh();return;}
var n=this.nodes[index];for(var i=0,len=records.length;i<len;i++){var d=this.prepareData(records[i].data);if(n){this.tpl.insertBefore(n,d);}else{this.tpl.append(this.el,d);}}
this.updateIndexes(index);},onRemove:function(ds,record,index){this.clearSelections();this.el.dom.removeChild(this.nodes[index]);this.updateIndexes(index);},refreshNode:function(index){this.onUpdate(this.store,this.store.getAt(index));},updateIndexes:function(startIndex,endIndex){var ns=this.nodes;startIndex=startIndex||0;endIndex=endIndex||ns.length-1;for(var i=startIndex;i<=endIndex;i++){ns[i].nodeIndex=i;}},setStore:function(store,initial){if(!initial&&this.store){this.store.un("datachanged",this.refresh,this);this.store.un("add",this.onAdd,this);this.store.un("remove",this.onRemove,this);this.store.un("update",this.onUpdate,this);this.store.un("clear",this.refresh,this);}
if(store){store.on("datachanged",this.refresh,this);store.on("add",this.onAdd,this);store.on("remove",this.onRemove,this);store.on("update",this.onUpdate,this);store.on("clear",this.refresh,this);}
this.store=store;if(store){this.refresh();}},findItemFromChild:function(node){var el=this.el.dom;if(!node||node.parentNode==el){return node;}
var p=node.parentNode;while(p&&p!=el){if(p.parentNode==el){return p;}
p=p.parentNode;}
return null;},onClick:function(e){var item=this.findItemFromChild(e.getTarget());if(item){var index=this.indexOf(item);if(this.onItemClick(item,index,e)!==false){this.fireEvent("click",this,index,item,e);}}else{this.clearSelections();}},onContextMenu:function(e){var item=this.findItemFromChild(e.getTarget());if(item){this.fireEvent("contextmenu",this,this.indexOf(item),item,e);}},onDblClick:function(e){var item=this.findItemFromChild(e.getTarget());if(item){this.fireEvent("dblclick",this,this.indexOf(item),item,e);}},onItemClick:function(item,index,e){if(this.fireEvent("beforeclick",this,index,item,e)===false){return false;}
if(this.multiSelect||this.singleSelect){if(this.multiSelect&&e.shiftKey&&this.lastSelection){this.select(this.getNodes(this.indexOf(this.lastSelection),index),false);}else{this.select(item,this.multiSelect&&e.ctrlKey);this.lastSelection=item;}
e.preventDefault();}
return true;},getSelectionCount:function(){return this.selections.length;},getSelectedNodes:function(){return this.selections;},getSelectedIndexes:function(){var indexes=[],s=this.selections;for(var i=0,len=s.length;i<len;i++){indexes.push(s[i].nodeIndex);}
return indexes;},clearSelections:function(suppressEvent){if(this.nodes&&(this.multiSelect||this.singleSelect)&&this.selections.length>0){this.cmp.elements=this.selections;this.cmp.removeClass(this.selectedClass);this.selections=[];if(!suppressEvent){this.fireEvent("selectionchange",this,this.selections);}}},isSelected:function(node){var s=this.selections;if(s.length<1){return false;}
node=this.getNode(node);return s.indexOf(node)!==-1;},select:function(nodeInfo,keepExisting,suppressEvent){if(Ext.isArray(nodeInfo)){if(!keepExisting){this.clearSelections(true);}
for(var i=0,len=nodeInfo.length;i<len;i++){this.select(nodeInfo[i],true,true);}}else{var node=this.getNode(nodeInfo);if(node&&!this.isSelected(node)){if(!keepExisting){this.clearSelections(true);}
if(this.fireEvent("beforeselect",this,node,this.selections)!==false){Ext.fly(node).addClass(this.selectedClass);this.selections.push(node);if(!suppressEvent){this.fireEvent("selectionchange",this,this.selections);}}}}},getNode:function(nodeInfo){if(typeof nodeInfo=="string"){return document.getElementById(nodeInfo);}else if(typeof nodeInfo=="number"){return this.nodes[nodeInfo];}
return nodeInfo;},getNodes:function(start,end){var ns=this.nodes;start=start||0;end=typeof end=="undefined"?ns.length-1:end;var nodes=[];if(start<=end){for(var i=start;i<=end;i++){nodes.push(ns[i]);}}else{for(var i=start;i>=end;i--){nodes.push(ns[i]);}}
return nodes;},indexOf:function(node){node=this.getNode(node);if(typeof node.nodeIndex=="number"){return node.nodeIndex;}
var ns=this.nodes;for(var i=0,len=ns.length;i<len;i++){if(ns[i]==node){return i;}}
return-1;}});