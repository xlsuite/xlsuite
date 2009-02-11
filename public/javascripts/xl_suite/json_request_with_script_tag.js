// function callbackFunc(jsonData) {
//      alert('Name = ' + jsonData.result.name);
//      jsonRequest.removeScriptTag();
// }
//
// jsonRequest = new JsonRequestWithScriptTag({});
// jsonRequest.runRequest();

// Constructor -- pass parameters
//  url: main url to retrieve the json in the absolute url format
//  params: additional parameters for the request
function JsonRequestWithScriptTag(parameters) {
  this.url = parameters.url;
  this.params = parameters.params;
  // Stop IE from caching requests
  this.params.noCacheIE = (new Date()).getTime();
  this.paramsInString = "";
  this.numOfParams = 0;
  for(var prop in this.params){
    this.paramsInString += ("&" + prop + "=" + this.params[prop]);
    this.numOfParams++;
  }
  if(this.numOfParams > 0){
    this.paramsInString = this.paramsInString.replace(new RegExp("&"), "?");
  }
  this.fullUrl = this.url + this.paramsInString;
  this.headLoc = document.getElementsByTagName("head").item(0);
  this.scriptId = 'JscriptId' + JsonRequestWithScriptTag.scriptCounter++;

  this.scriptObj = document.createElement("script");
  
  this.scriptObj.setAttribute("type", "text/javascript");
  this.scriptObj.setAttribute("charset", "utf-8");
  this.scriptObj.setAttribute("src", this.fullUrl);
  this.scriptObj.setAttribute("id", this.scriptId);
  this.headLoc.appendChild(this.scriptObj);
}

JsonRequestWithScriptTag.scriptCounter = 1;

JsonRequestWithScriptTag.prototype.removeScriptTag = function () {
    this.headLoc.removeChild(this.scriptObj);  
}
