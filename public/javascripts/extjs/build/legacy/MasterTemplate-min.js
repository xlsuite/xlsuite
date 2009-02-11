/*
 * Ext JS Library 2.0.2
 * Copyright(c) 2006-2008, Ext JS, LLC.
 * licensing@extjs.com
 * 
 * http://extjs.com/license
 */


Ext.MasterTemplate=function(){Ext.MasterTemplate.superclass.constructor.apply(this,arguments);this.originalHtml=this.html;var st={};var m,re=this.subTemplateRe;re.lastIndex=0;var subIndex=0;while(m=re.exec(this.html)){var name=m[1],content=m[2];st[subIndex]={name:name,index:subIndex,buffer:[],tpl:new Ext.Template(content)};if(name){st[name]=st[subIndex];}
st[subIndex].tpl.compile();st[subIndex].tpl.call=this.call.createDelegate(this);subIndex++;}
this.subCount=subIndex;this.subs=st;};Ext.extend(Ext.MasterTemplate,Ext.Template,{subTemplateRe:/<tpl(?:\sname="([\w-]+)")?>((?:.|\n)*?)<\/tpl>/gi,add:function(name,values){if(arguments.length==1){values=arguments[0];name=0;}
var s=this.subs[name];s.buffer[s.buffer.length]=s.tpl.apply(values);return this;},fill:function(name,values,reset){var a=arguments;if(a.length==1||(a.length==2&&typeof a[1]=="boolean")){values=a[0];name=0;reset=a[1];}
if(reset){this.reset();}
for(var i=0,len=values.length;i<len;i++){this.add(name,values[i]);}
return this;},reset:function(){var s=this.subs;for(var i=0;i<this.subCount;i++){s[i].buffer=[];}
return this;},applyTemplate:function(values){var s=this.subs;var replaceIndex=-1;this.html=this.originalHtml.replace(this.subTemplateRe,function(m,name){return s[++replaceIndex].buffer.join("");});return Ext.MasterTemplate.superclass.applyTemplate.call(this,values);},apply:function(){return this.applyTemplate.apply(this,arguments);},compile:function(){return this;}});Ext.MasterTemplate.prototype.addAll=Ext.MasterTemplate.prototype.fill;Ext.MasterTemplate.from=function(el,config){el=Ext.getDom(el);return new Ext.MasterTemplate(el.value||el.innerHTML,config||'');};