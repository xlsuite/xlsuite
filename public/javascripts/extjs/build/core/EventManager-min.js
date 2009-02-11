/*
 * Ext JS Library 2.1
 * Copyright(c) 2006-2008, Ext JS, LLC.
 * licensing@extjs.com
 * 
 * http://extjs.com/license
 */


Ext.EventManager=function(){var docReadyEvent,docReadyProcId,docReadyState=false;var resizeEvent,resizeTask,textEvent,textSize;var E=Ext.lib.Event;var D=Ext.lib.Dom;var fireDocReady=function(){if(!docReadyState){docReadyState=true;Ext.isReady=true;if(docReadyProcId){clearInterval(docReadyProcId);}
if(Ext.isGecko||Ext.isOpera){document.removeEventListener("DOMContentLoaded",fireDocReady,false);}
if(Ext.isIE){var defer=document.getElementById("ie-deferred-loader");if(defer){defer.onreadystatechange=null;defer.parentNode.removeChild(defer);}}
if(docReadyEvent){docReadyEvent.fire();docReadyEvent.clearListeners();}}};var initDocReady=function(){docReadyEvent=new Ext.util.Event();if(Ext.isGecko||Ext.isOpera){document.addEventListener("DOMContentLoaded",fireDocReady,false);}else if(Ext.isIE){document.write("<s"+'cript id="ie-deferred-loader" defer="defer" src="/'+'/:"></s'+"cript>");var defer=document.getElementById("ie-deferred-loader");defer.onreadystatechange=function(){if(this.readyState=="complete"){fireDocReady();}};}else if(Ext.isSafari){docReadyProcId=setInterval(function(){var rs=document.readyState;if(rs=="complete"){fireDocReady();}},10);}
E.on(window,"load",fireDocReady);};var createBuffered=function(h,o){var task=new Ext.util.DelayedTask(h);return function(e){e=new Ext.EventObjectImpl(e);task.delay(o.buffer,h,null,[e]);};};var createSingle=function(h,el,ename,fn){return function(e){Ext.EventManager.removeListener(el,ename,fn);h(e);};};var createDelayed=function(h,o){return function(e){e=new Ext.EventObjectImpl(e);setTimeout(function(){h(e);},o.delay||10);};};var listen=function(element,ename,opt,fn,scope){var o=(!opt||typeof opt=="boolean")?{}:opt;fn=fn||o.fn;scope=scope||o.scope;var el=Ext.getDom(element);if(!el){throw"Error listening for \""+ename+'\". Element "'+element+'" doesn\'t exist.';}
var h=function(e){e=Ext.EventObject.setEvent(e);var t;if(o.delegate){t=e.getTarget(o.delegate,el);if(!t){return;}}else{t=e.target;}
if(o.stopEvent===true){e.stopEvent();}
if(o.preventDefault===true){e.preventDefault();}
if(o.stopPropagation===true){e.stopPropagation();}
if(o.normalized===false){e=e.browserEvent;}
fn.call(scope||el,e,t,o);};if(o.delay){h=createDelayed(h,o);}
if(o.single){h=createSingle(h,el,ename,fn);}
if(o.buffer){h=createBuffered(h,o);}
fn._handlers=fn._handlers||[];fn._handlers.push([Ext.id(el),ename,h]);E.on(el,ename,h);if(ename=="mousewheel"&&el.addEventListener){el.addEventListener("DOMMouseScroll",h,false);E.on(window,'unload',function(){el.removeEventListener("DOMMouseScroll",h,false);});}
if(ename=="mousedown"&&el==document){Ext.EventManager.stoppedMouseDownEvent.addListener(h);}
return h;};var stopListening=function(el,ename,fn){var id=Ext.id(el),hds=fn._handlers,hd=fn;if(hds){for(var i=0,len=hds.length;i<len;i++){var h=hds[i];if(h[0]==id&&h[1]==ename){hd=h[2];hds.splice(i,1);break;}}}
E.un(el,ename,hd);el=Ext.getDom(el);if(ename=="mousewheel"&&el.addEventListener){el.removeEventListener("DOMMouseScroll",hd,false);}
if(ename=="mousedown"&&el==document){Ext.EventManager.stoppedMouseDownEvent.removeListener(hd);}};var propRe=/^(?:scope|delay|buffer|single|stopEvent|preventDefault|stopPropagation|normalized|args|delegate)$/;var pub={addListener:function(element,eventName,fn,scope,options){if(typeof eventName=="object"){var o=eventName;for(var e in o){if(propRe.test(e)){continue;}
if(typeof o[e]=="function"){listen(element,e,o,o[e],o.scope);}else{listen(element,e,o[e]);}}
return;}
return listen(element,eventName,options,fn,scope);},removeListener:function(element,eventName,fn){return stopListening(element,eventName,fn);},onDocumentReady:function(fn,scope,options){if(docReadyState){docReadyEvent.addListener(fn,scope,options);docReadyEvent.fire();docReadyEvent.clearListeners();return;}
if(!docReadyEvent){initDocReady();}
docReadyEvent.addListener(fn,scope,options);},onWindowResize:function(fn,scope,options){if(!resizeEvent){resizeEvent=new Ext.util.Event();resizeTask=new Ext.util.DelayedTask(function(){resizeEvent.fire(D.getViewWidth(),D.getViewHeight());});E.on(window,"resize",this.fireWindowResize,this);}
resizeEvent.addListener(fn,scope,options);},fireWindowResize:function(){if(resizeEvent){if((Ext.isIE||Ext.isAir)&&resizeTask){resizeTask.delay(50);}else{resizeEvent.fire(D.getViewWidth(),D.getViewHeight());}}},onTextResize:function(fn,scope,options){if(!textEvent){textEvent=new Ext.util.Event();var textEl=new Ext.Element(document.createElement('div'));textEl.dom.className='x-text-resize';textEl.dom.innerHTML='X';textEl.appendTo(document.body);textSize=textEl.dom.offsetHeight;setInterval(function(){if(textEl.dom.offsetHeight!=textSize){textEvent.fire(textSize,textSize=textEl.dom.offsetHeight);}},this.textResizeInterval);}
textEvent.addListener(fn,scope,options);},removeResizeListener:function(fn,scope){if(resizeEvent){resizeEvent.removeListener(fn,scope);}},fireResize:function(){if(resizeEvent){resizeEvent.fire(D.getViewWidth(),D.getViewHeight());}},ieDeferSrc:false,textResizeInterval:50};pub.on=pub.addListener;pub.un=pub.removeListener;pub.stoppedMouseDownEvent=new Ext.util.Event();return pub;}();Ext.onReady=Ext.EventManager.onDocumentReady;Ext.onReady(function(){var bd=Ext.getBody();if(!bd){return;}
var cls=[Ext.isIE?"ext-ie "+(Ext.isIE6?'ext-ie6':'ext-ie7'):Ext.isGecko?"ext-gecko":Ext.isOpera?"ext-opera":Ext.isSafari?"ext-safari":""];if(Ext.isMac){cls.push("ext-mac");}
if(Ext.isLinux){cls.push("ext-linux");}
if(Ext.isBorderBox){cls.push('ext-border-box');}
if(Ext.isStrict){var p=bd.dom.parentNode;if(p){p.className+=' ext-strict';}}
bd.addClass(cls.join(' '));});Ext.EventObject=function(){var E=Ext.lib.Event;var safariKeys={63234:37,63235:39,63232:38,63233:40,63276:33,63277:34,63272:46,63273:36,63275:35};var btnMap=Ext.isIE?{1:0,4:1,2:2}:(Ext.isSafari?{1:0,2:1,3:2}:{0:0,1:1,2:2});Ext.EventObjectImpl=function(e){if(e){this.setEvent(e.browserEvent||e);}};Ext.EventObjectImpl.prototype={browserEvent:null,button:-1,shiftKey:false,ctrlKey:false,altKey:false,BACKSPACE:8,TAB:9,RETURN:13,ENTER:13,SHIFT:16,CONTROL:17,ESC:27,SPACE:32,PAGEUP:33,PAGEDOWN:34,END:35,HOME:36,LEFT:37,UP:38,RIGHT:39,DOWN:40,DELETE:46,F5:116,setEvent:function(e){if(e==this||(e&&e.browserEvent)){return e;}
this.browserEvent=e;if(e){this.button=e.button?btnMap[e.button]:(e.which?e.which-1:-1);if(e.type=='click'&&this.button==-1){this.button=0;}
this.type=e.type;this.shiftKey=e.shiftKey;this.ctrlKey=e.ctrlKey||e.metaKey;this.altKey=e.altKey;this.keyCode=e.keyCode;this.charCode=e.charCode;this.target=E.getTarget(e);this.xy=E.getXY(e);}else{this.button=-1;this.shiftKey=false;this.ctrlKey=false;this.altKey=false;this.keyCode=0;this.charCode=0;this.target=null;this.xy=[0,0];}
return this;},stopEvent:function(){if(this.browserEvent){if(this.browserEvent.type=='mousedown'){Ext.EventManager.stoppedMouseDownEvent.fire(this);}
E.stopEvent(this.browserEvent);}},preventDefault:function(){if(this.browserEvent){E.preventDefault(this.browserEvent);}},isNavKeyPress:function(){var k=this.keyCode;k=Ext.isSafari?(safariKeys[k]||k):k;return(k>=33&&k<=40)||k==this.RETURN||k==this.TAB||k==this.ESC;},isSpecialKey:function(){var k=this.keyCode;return(this.type=='keypress'&&this.ctrlKey)||k==9||k==13||k==40||k==27||(k==16)||(k==17)||(k>=18&&k<=20)||(k>=33&&k<=35)||(k>=36&&k<=39)||(k>=44&&k<=45);},stopPropagation:function(){if(this.browserEvent){if(this.browserEvent.type=='mousedown'){Ext.EventManager.stoppedMouseDownEvent.fire(this);}
E.stopPropagation(this.browserEvent);}},getCharCode:function(){return this.charCode||this.keyCode;},getKey:function(){var k=this.keyCode||this.charCode;return Ext.isSafari?(safariKeys[k]||k):k;},getPageX:function(){return this.xy[0];},getPageY:function(){return this.xy[1];},getTime:function(){if(this.browserEvent){return E.getTime(this.browserEvent);}
return null;},getXY:function(){return this.xy;},getTarget:function(selector,maxDepth,returnEl){return selector?Ext.fly(this.target).findParent(selector,maxDepth,returnEl):(returnEl?Ext.get(this.target):this.target);},getRelatedTarget:function(){if(this.browserEvent){return E.getRelatedTarget(this.browserEvent);}
return null;},getWheelDelta:function(){var e=this.browserEvent;var delta=0;if(e.wheelDelta){delta=e.wheelDelta/120;}else if(e.detail){delta=-e.detail/3;}
return delta;},hasModifier:function(){return((this.ctrlKey||this.altKey)||this.shiftKey)?true:false;},within:function(el,related){var t=this[related?"getRelatedTarget":"getTarget"]();return t&&Ext.fly(el).contains(t);},getPoint:function(){return new Ext.lib.Point(this.xy[0],this.xy[1]);}};return new Ext.EventObjectImpl();}();