/*
 * Ext JS Library 2.1
 * Copyright(c) 2006-2008, Ext JS, LLC.
 * licensing@extjs.com
 * 
 * http://extjs.com/license
 */


Ext.util.DelayedTask=function(fn,scope,args){var id=null,d,t;var call=function(){var now=new Date().getTime();if(now-t>=d){clearInterval(id);id=null;fn.apply(scope,args||[]);}};this.delay=function(delay,newFn,newScope,newArgs){if(id&&delay!=d){this.cancel();}
d=delay;t=new Date().getTime();fn=newFn||fn;scope=newScope||scope;args=newArgs||args;if(!id){id=setInterval(call,d);}};this.cancel=function(){if(id){clearInterval(id);id=null;}};};