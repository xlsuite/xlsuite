/*
 * Ext JS Library 2.1
 * Copyright(c) 2006-2008, Ext JS, LLC.
 * licensing@extjs.com
 * 
 * http://extjs.com/license
 */


Date.parseFunctions={count:0};Date.parseRegexes=[];Date.formatFunctions={count:0};Date.prototype.dateFormat=function(format){if(Date.formatFunctions[format]==null){Date.createNewFormat(format);}
var func=Date.formatFunctions[format];return this[func]();};Date.prototype.format=Date.prototype.dateFormat;Date.createNewFormat=function(format){var funcName="format"+Date.formatFunctions.count++;Date.formatFunctions[format]=funcName;var code="Date.prototype."+funcName+" = function(){return ";var special=false;var ch='';for(var i=0;i<format.length;++i){ch=format.charAt(i);if(!special&&ch=="\\"){special=true;}
else if(special){special=false;code+="'"+String.escape(ch)+"' + ";}
else{code+=Date.getFormatCode(ch)+" + ";}}
eval(code.substring(0,code.length-3)+";}");};Date.formatCodes={d:"String.leftPad(this.getDate(), 2, '0')",D:"Date.getShortDayName(this.getDay())",j:"this.getDate()",l:"Date.dayNames[this.getDay()]",N:"(this.getDay() ? this.getDay() : 7)",S:"this.getSuffix()",w:"this.getDay()",z:"this.getDayOfYear()",W:"String.leftPad(this.getWeekOfYear(), 2, '0')",F:"Date.monthNames[this.getMonth()]",m:"String.leftPad(this.getMonth() + 1, 2, '0')",M:"Date.getShortMonthName(this.getMonth())",n:"(this.getMonth() + 1)",t:"this.getDaysInMonth()",L:"(this.isLeapYear() ? 1 : 0)",o:"(this.getFullYear() + (this.getWeekOfYear() == 1 && this.getMonth() > 0 ? +1 : (this.getWeekOfYear() >= 52 && this.getMonth() < 11 ? -1 : 0)))",Y:"this.getFullYear()",y:"('' + this.getFullYear()).substring(2, 4)",a:"(this.getHours() < 12 ? 'am' : 'pm')",A:"(this.getHours() < 12 ? 'AM' : 'PM')",g:"((this.getHours() % 12) ? this.getHours() % 12 : 12)",G:"this.getHours()",h:"String.leftPad((this.getHours() % 12) ? this.getHours() % 12 : 12, 2, '0')",H:"String.leftPad(this.getHours(), 2, '0')",i:"String.leftPad(this.getMinutes(), 2, '0')",s:"String.leftPad(this.getSeconds(), 2, '0')",u:"String.leftPad(this.getMilliseconds(), 3, '0')",O:"this.getGMTOffset()",P:"this.getGMTOffset(true)",T:"this.getTimezone()",Z:"(this.getTimezoneOffset() * -60)",c:function(){for(var c="Y-m-dTH:i:sP",code=[],i=0,l=c.length;i<l;++i){var e=c.charAt(i);code.push(e=="T"?"'T'":Date.getFormatCode(e));}
return code.join(" + ");},U:"Math.round(this.getTime() / 1000)"}
Date.getFormatCode=function(character){var f=Date.formatCodes[character];if(f){f=Ext.type(f)=='function'?f():f;Date.formatCodes[character]=f;}
return f||("'"+String.escape(character)+"'");};Date.parseDate=function(input,format){if(Date.parseFunctions[format]==null){Date.createParser(format);}
var func=Date.parseFunctions[format];return Date[func](input);};Date.createParser=function(format){var funcName="parse"+Date.parseFunctions.count++;var regexNum=Date.parseRegexes.length;var currentGroup=1;Date.parseFunctions[format]=funcName;var code="Date."+funcName+" = function(input){\n"
+"var y = -1, m = -1, d = -1, h = -1, i = -1, s = -1, ms = -1, o, z, u, v;\n"
+"input = String(input);var d = new Date();\n"
+"y = d.getFullYear();\n"
+"m = d.getMonth();\n"
+"d = d.getDate();\n"
+"var results = input.match(Date.parseRegexes["+regexNum+"]);\n"
+"if (results && results.length > 0) {";var regex="";var special=false;var ch='';for(var i=0;i<format.length;++i){ch=format.charAt(i);if(!special&&ch=="\\"){special=true;}
else if(special){special=false;regex+=String.escape(ch);}
else{var obj=Date.formatCodeToRegex(ch,currentGroup);currentGroup+=obj.g;regex+=obj.s;if(obj.g&&obj.c){code+=obj.c;}}}
code+="if (u){\n"
+"v = new Date(u * 1000);\n"
+"}else if (y >= 0 && m >= 0 && d > 0 && h >= 0 && i >= 0 && s >= 0 && ms >= 0){\n"
+"v = new Date(y, m, d, h, i, s, ms);\n"
+"}else if (y >= 0 && m >= 0 && d > 0 && h >= 0 && i >= 0 && s >= 0){\n"
+"v = new Date(y, m, d, h, i, s);\n"
+"}else if (y >= 0 && m >= 0 && d > 0 && h >= 0 && i >= 0){\n"
+"v = new Date(y, m, d, h, i);\n"
+"}else if (y >= 0 && m >= 0 && d > 0 && h >= 0){\n"
+"v = new Date(y, m, d, h);\n"
+"}else if (y >= 0 && m >= 0 && d > 0){\n"
+"v = new Date(y, m, d);\n"
+"}else if (y >= 0 && m >= 0){\n"
+"v = new Date(y, m);\n"
+"}else if (y >= 0){\n"
+"v = new Date(y);\n"
+"}\n}\nreturn (v && Ext.type(z || o) == 'number')?"
+" (Ext.type(z) == 'number' ? v.add(Date.SECOND, (v.getTimezoneOffset() * 60) + z) :"
+" v.add(Date.HOUR, (v.getGMTOffset() / 100) + (o / -100))) : v;\n"
+"}";Date.parseRegexes[regexNum]=new RegExp("^"+regex+"$","i");eval(code);};Date.parseCodes={d:{g:1,c:"d = parseInt(results[{0}], 10);\n",s:"(\\d{2})"},j:{g:1,c:"d = parseInt(results[{0}], 10);\n",s:"(\\d{1,2})"},D:function(){for(var a=[],i=0;i<7;a.push(Date.getShortDayName(i)),++i);return{g:0,c:null,s:"(?:"+a.join("|")+")"}},l:function(){return{g:0,c:null,s:"(?:"+Date.dayNames.join("|")+")"}},N:{g:0,c:null,s:"[1-7]"},S:{g:0,c:null,s:"(?:st|nd|rd|th)"},w:{g:0,c:null,s:"[0-6]"},z:{g:0,c:null,s:"(?:\\d{1,3}"},W:{g:0,c:null,s:"(?:\\d{2})"},F:function(){return{g:1,c:"m = parseInt(Date.getMonthNumber(results[{0}]), 10);\n",s:"("+Date.monthNames.join("|")+")"}},M:function(){for(var a=[],i=0;i<12;a.push(Date.getShortMonthName(i)),++i);return Ext.applyIf({s:"("+a.join("|")+")"},Date.formatCodeToRegex("F"));},m:{g:1,c:"m = parseInt(results[{0}], 10) - 1;\n",s:"(\\d{2})"},n:{g:1,c:"m = parseInt(results[{0}], 10) - 1;\n",s:"(\\d{1,2})"},t:{g:0,c:null,s:"(?:\\d{2})"},L:{g:0,c:null,s:"(?:1|0)"},o:function(){return Date.formatCodeToRegex("Y");},Y:{g:1,c:"y = parseInt(results[{0}], 10);\n",s:"(\\d{4})"},y:{g:1,c:"var ty = parseInt(results[{0}], 10);\n"
+"y = ty > Date.y2kYear ? 1900 + ty : 2000 + ty;\n",s:"(\\d{1,2})"},a:{g:1,c:"if (results[{0}] == 'am') {\n"
+"if (h == 12) { h = 0; }\n"
+"} else { if (h < 12) { h += 12; }}",s:"(am|pm)"},A:{g:1,c:"if (results[{0}] == 'AM') {\n"
+"if (h == 12) { h = 0; }\n"
+"} else { if (h < 12) { h += 12; }}",s:"(AM|PM)"},g:function(){return Date.formatCodeToRegex("G");},G:{g:1,c:"h = parseInt(results[{0}], 10);\n",s:"(\\d{1,2})"},h:function(){return Date.formatCodeToRegex("H");},H:{g:1,c:"h = parseInt(results[{0}], 10);\n",s:"(\\d{2})"},i:{g:1,c:"i = parseInt(results[{0}], 10);\n",s:"(\\d{2})"},s:{g:1,c:"s = parseInt(results[{0}], 10);\n",s:"(\\d{2})"},u:{g:1,c:"ms = parseInt(results[{0}], 10);\n",s:"(\\d{3})"},O:{g:1,c:["o = results[{0}];","var sn = o.substring(0,1);","var hr = o.substring(1,3)*1 + Math.floor(o.substring(3,5) / 60);","var mn = o.substring(3,5) % 60;","o = ((-12 <= (hr*60 + mn)/60) && ((hr*60 + mn)/60 <= 14))? (sn + String.leftPad(hr, 2, '0') + String.leftPad(mn, 2, '0')) : null;\n"].join("\n"),s:"([+\-]\\d{4})"},P:function(){return Ext.applyIf({s:"([+\-]\\d{2}:\\d{2})"},Date.formatCodeToRegex("O"));},T:{g:0,c:null,s:"[A-Z]{1,4}"},Z:{g:1,c:"z = results[{0}] * 1;\n"
+"z = (-43200 <= z && z <= 50400)? z : null;\n",s:"([+\-]?\\d{1,5})"},c:function(){var df=Date.formatCodeToRegex,calc=[];var arr=[df("Y",1),df("m",2),df("d",3),df("h",4),df("i",5),df("s",6),{c:"if(results[7] == 'Z'){\no = 0;\n}else{\n"+df("P",7).c+"\n}"}];for(var i=0,l=arr.length;i<l;++i){calc.push(arr[i].c);}
return{g:1,c:calc.join(""),s:arr[0].s+"-"+arr[1].s+"-"+arr[2].s+"T"+arr[3].s+":"+arr[4].s+":"+arr[5].s+"("+df("P",7).s+"|Z)"}},U:{g:1,c:"u = parseInt(results[{0}], 10);\n",s:"(-?\\d+)"}}
Date.formatCodeToRegex=function(character,currentGroup){var p=Date.parseCodes[character];if(p){p=Ext.type(p)=='function'?p():p;Date.parseCodes[character]=p;}
return p?Ext.applyIf({c:p.c?String.format(p.c,currentGroup||"{0}"):p.c},p):{g:0,c:null,s:Ext.escapeRe(character)}};Date.prototype.getTimezone=function(){return this.toString().replace(/^.* (?:\((.*)\)|([A-Z]{1,4})(?:[\-+][0-9]{4})?(?: -?\d+)?)$/,"$1$2").replace(/[^A-Z]/g,"");};Date.prototype.getGMTOffset=function(colon){return(this.getTimezoneOffset()>0?"-":"+")
+String.leftPad(Math.abs(Math.floor(this.getTimezoneOffset()/60)),2,"0")
+(colon?":":"")
+String.leftPad(this.getTimezoneOffset()%60,2,"0");};Date.prototype.getDayOfYear=function(){var num=0;Date.daysInMonth[1]=this.isLeapYear()?29:28;for(var i=0;i<this.getMonth();++i){num+=Date.daysInMonth[i];}
return num+this.getDate()-1;};Date.prototype.getWeekOfYear=function(){var ms1d=864e5;var ms7d=7*ms1d;var DC3=Date.UTC(this.getFullYear(),this.getMonth(),this.getDate()+3)/ms1d;var AWN=Math.floor(DC3/7);var Wyr=new Date(AWN*ms7d).getUTCFullYear();return AWN-Math.floor(Date.UTC(Wyr,0,7)/ms7d)+1;};Date.prototype.isLeapYear=function(){var year=this.getFullYear();return!!((year&3)==0&&(year%100||(year%400==0&&year)));};Date.prototype.getFirstDayOfMonth=function(){var day=(this.getDay()-(this.getDate()-1))%7;return(day<0)?(day+7):day;};Date.prototype.getLastDayOfMonth=function(){var day=(this.getDay()+(Date.daysInMonth[this.getMonth()]-this.getDate()))%7;return(day<0)?(day+7):day;};Date.prototype.getFirstDateOfMonth=function(){return new Date(this.getFullYear(),this.getMonth(),1);};Date.prototype.getLastDateOfMonth=function(){return new Date(this.getFullYear(),this.getMonth(),this.getDaysInMonth());};Date.prototype.getDaysInMonth=function(){Date.daysInMonth[1]=this.isLeapYear()?29:28;return Date.daysInMonth[this.getMonth()];};Date.prototype.getSuffix=function(){switch(this.getDate()){case 1:case 21:case 31:return"st";case 2:case 22:return"nd";case 3:case 23:return"rd";default:return"th";}};Date.daysInMonth=[31,28,31,30,31,30,31,31,30,31,30,31];Date.monthNames=["January","February","March","April","May","June","July","August","September","October","November","December"];Date.getShortMonthName=function(month){return Date.monthNames[month].substring(0,3);}
Date.dayNames=["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"];Date.getShortDayName=function(day){return Date.dayNames[day].substring(0,3);}
Date.y2kYear=50;Date.monthNumbers={Jan:0,Feb:1,Mar:2,Apr:3,May:4,Jun:5,Jul:6,Aug:7,Sep:8,Oct:9,Nov:10,Dec:11};Date.getMonthNumber=function(name){return Date.monthNumbers[name.substring(0,1).toUpperCase()+name.substring(1,3).toLowerCase()];}
Date.prototype.clone=function(){return new Date(this.getTime());};Date.prototype.clearTime=function(clone){if(clone){return this.clone().clearTime();}
this.setHours(0);this.setMinutes(0);this.setSeconds(0);this.setMilliseconds(0);return this;};if(Ext.isSafari){Date.brokenSetMonth=Date.prototype.setMonth;Date.prototype.setMonth=function(num){if(num<=-1){var n=Math.ceil(-num);var back_year=Math.ceil(n/12);var month=(n%12)?12-n%12:0;this.setFullYear(this.getFullYear()-back_year);return Date.brokenSetMonth.call(this,month);}else{return Date.brokenSetMonth.apply(this,arguments);}};}
Date.MILLI="ms";Date.SECOND="s";Date.MINUTE="mi";Date.HOUR="h";Date.DAY="d";Date.MONTH="mo";Date.YEAR="y";Date.prototype.add=function(interval,value){var d=this.clone();if(!interval||value===0)return d;switch(interval.toLowerCase()){case Date.MILLI:d.setMilliseconds(this.getMilliseconds()+value);break;case Date.SECOND:d.setSeconds(this.getSeconds()+value);break;case Date.MINUTE:d.setMinutes(this.getMinutes()+value);break;case Date.HOUR:d.setHours(this.getHours()+value);break;case Date.DAY:d.setDate(this.getDate()+value);break;case Date.MONTH:var day=this.getDate();if(day>28){day=Math.min(day,this.getFirstDateOfMonth().add('mo',value).getLastDateOfMonth().getDate());}
d.setDate(day);d.setMonth(this.getMonth()+value);break;case Date.YEAR:d.setFullYear(this.getFullYear()+value);break;}
return d;};Date.prototype.between=function(start,end){var t=this.getTime();return start.getTime()<=t&&t<=end.getTime();}
