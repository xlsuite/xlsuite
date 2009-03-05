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

var toggleInstallForm = function(suiteId){
  var installButton = document.getElementById("xlsuite-install-button-"+suiteId);
  if(installButton.value=="INSTALL"){
    installButton.value = "CANCEL";
    displayInstallForm(suiteId);
  }
  else if(installButton.value=="CANCEL"){
    installButton.value = "INSTALL";
    hideInstallForm(suiteId);
  }
}

var displayInstallForm = function(suiteId){
  Ext.get("xlsuite-install-form-"+suiteId).show();
}

var hideInstallForm = function(suiteId){
  Ext.get("xlsuite-install-form-"+suiteId).hide();
}

var xlsuiteValidEmail = false;
var xlsuiteValidDomainName = false;
var currentSuiteId = null;

var doEmailCheck = function(suiteId){
  xlsuiteValidEmail = false;
  currentSuiteId = suiteId;
  var emailAddress = document.getElementById("account-signup-email-address-" + suiteId.toString()).value;
  var emailAddressStatus = document.getElementById("account-signup-email-checker-status-"+suiteId.toString());
  if(validEmailFormat(emailAddress)){
    emailAddressStatus.innerHTML = "Email validated";
    xlsuiteValidEmail = true;
  }
  else{
    emailAddressStatus.innerHTML = "Invalid email";
    xlsuiteValidEmail = false;
  }
  disableEnableSubmitButton();
}

var validEmailFormat = function(address){
  var emailRegExp = new RegExp("[A-Z0-9._%-]+@[A-Z0-9.-]+\\.[A-Z]{2,}", "gi")
  if(address.match(emailRegExp)){return true;}
  return false;
}

var doDomainNameCheck = function(suiteId){
  xlsuiteValidDomainName = false;
  currentSuiteId = suiteId;
  var domainName = document.getElementById('account-signup-domain-name-checker-'+suiteId.toString()).value + "." + getReferralDomain();
  suitesJsonRequest = new JsonRequestWithScriptTag({
    url:getAjaxRequestUrl()+"/admin/domains/validate_name",
    params: {callback:"updateDomainNameCheckerStatus", name:domainName}
  });
}

var updateDomainNameCheckerStatus = function(response){
  var domainNameStatus = document.getElementById("account-signup-domain-checker-status-" + currentSuiteId.toString());
  if(response.valid){
    domainNameStatus.innerHTML = "Available";
    xlsuiteValidDomainName = true;
  }
  else{
    domainNameStatus.innerHTML = response.errors;
    xlsuiteValidDomainName = false;
  }
  disableEnableSubmitButton();
  var domainName = document.getElementById('account-signup-domain-name-checker-'+currentSuiteId.toString()).value + "." + getReferralDomain();
  document.getElementById("account-signup-domain-name-"+currentSuiteId.toString()).value = domainName;
}

var disableEnableSubmitButton = function(){
  var submitButton = document.getElementById("account-signup-submit-button-"+currentSuiteId.toString());
  if(xlsuiteValidEmail && xlsuiteValidDomainName){
    submitButton.disabled = false;
  }
  else{
    submitButton.disabled = true;
  }
}

var xlSuiteEmbedBody = function(suitesCollection){
  var htmlCode = "";
  var suiteXTemplate = new Ext.XTemplate(
    "<li class='xlsuite-embed-suite-item'>",
       "<img src='{main_image_url}?size=medium' alt='' title='' class='xlsuite-embed-suite-item-main-image'/>",
       "<div class='xlsuite-embed-suite-item-details'>",
         "<h2><a href='{demo_url}'>{name}</a></h2>",
         "<dl>",
           "<dt>Designer</dt>",
           "<dd>{designer_name}</dd>",
           "<dt>Description</dt>",
           "<dd>{description}</dd>",
           "<dt>Tags</dt>",
           "<dd>{tag_list}</dd>",
           "<dt>Installed</dt>",
           "<dd>{installed_count} times</dd>",
           "<dt>Features</dt>",
           "<dd>{features_list}</dd>",
           "<dt>Installation Fee</dt>",
           "<dd>{setup_fee}</dd>",
           "<dt>Monthly Fee</dt>",
           "<dd>{subscription_fee}</dd>",
         "</dl>",
       "</div>",
       "<div class='xlsuite-embed-suite-more-info'>",
         "<p>All of our suites come with a 60 day free trial. No credit card required for signup, just your email address.</p>",
         "<p>Start with a subdomain and try it out to make sure it meets your needs.<span class='xlsuite-embed-suite-more-info-second-line'>yourname.xlsuite.com - free to try for 60 days</span></p>",
         "<p>You pay when you are ready to point your own domain name to the account.<span class='xlsuite-embed-suite-more-info-second-line'>yourname.com - Pay the installation fee and start with recurring monthly fee</span></p>",
       "</div>",
       "<form style='display:none;' id='xlsuite-install-form-{id}' class='xlsuite-embed-suite-item-form' action='http://", getReferralDomain(), "/admin/accounts' method='post'>",
         "<input type='hidden' name='account[referral_domain]' value='", getReferralDomain(), "' />",
         "<input type='hidden' name='account[suite_id]' value='{id}' />",
         "<input type='hidden' value='' name='domain[name]' autocomplete='off' id='account-signup-domain-name-{id}'/>",
         "<span id='account-signup-domain-checker-status-{id}' class='account-signup-domain-checker-status'></span>",
         "<span id='account-signup-email-checker-status-{id}' class='account-signup-email-checker-status'></span>",
         "<input class='account_signup_domain_name_check' onblur='doDomainNameCheck({id});return false;' onfocus='this.select();return false;' value='choose a subdomain' name='' autocomplete='off' id='account-signup-domain-name-checker-{id}'/>",
         getReferralDomain(),
         '<input class="account_signup_email_check" onblur="doEmailCheck({id});return false;" onkeyup="doEmailCheck({id});return false" onfocus="this.select();return false;" value="enter your email" name="email[email_address]" autocomplete="off" id="account-signup-email-address-{id}"/>',
         "<input class='account_signup_button' id='account-signup-submit-button-{id}' disabled='true' type='submit' value='SUBMIT' />",
       "</form>",
       "<input class='xlsuite_install_button' id='xlsuite-install-button-{id}' type='submit' value='INSTALL' onclick='toggleInstallForm({id}); return false;'>",
    "</li>"
  );
  for (var i = 0; i < suitesCollection.length; i++) {
    htmlCode += suiteXTemplate.apply(suitesCollection[i]);
  }
  return htmlCode;
};

var updateSuitesCatalogBody = function(){
  var searchBarForm = new Ext.form.BasicForm("xlsuite-embed-suites-search-bar-form");
  generateSuitesCatalogBody(searchBarForm.getValues(false));
  return false;
};

var industriesJsonRequest = null;
var mainThemesJsonRequest = null;
var tagListJsonRequest = null;
var optionXTemplate = new Ext.XTemplate(
  "<option value='{label}'>{name}</option>"
);
var tagXTemplate = new Ext.XTemplate(
  "<option value='{name}'>{name}</option>"
);

var generateSearchBarIndustriesSelection = function(response){
  var industriesContainer = document.getElementById("xlsuite-embed-suites-search-bar-industries-container");
  var htmlCode = "";
  htmlCode += "<select id='xlsuite-embed-suites-search-bar-industries' name='industry'>";
  htmlCode += "<option value='all'>Industry</option>";
  var industriesCollection = response.collection;
  
  for (var i = 0; i < industriesCollection.length; i++) {
    htmlCode += optionXTemplate.apply(industriesCollection[i]);
  }
  
  htmlCode += "</select>";
  industriesContainer.innerHTML = htmlCode;
  industriesJsonRequest.removeScriptTag();
};

var generateSearchBarMainThemesSelection = function(response){
  var mainThemesContainer = document.getElementById("xlsuite-embed-suites-search-bar-main_themes-container");
  var htmlCode = "";
  htmlCode += "<select id='xlsuite-embed-suites-search-bar-main_themes' name='main_theme'>";
  var mainThemesCollection = response.collection;
  htmlCode += "<option value='all'>Main theme</option>";
  
  for (var i = 0; i < mainThemesCollection.length; i++) {
    htmlCode += optionXTemplate.apply(mainThemesCollection[i]);
  }

  htmlCode += "</select>";
  mainThemesContainer.innerHTML = htmlCode;
  mainThemesJsonRequest.removeScriptTag();
};

var generateSearchBarTagListSelection = function(response){
  var tagListContainer = document.getElementById("xlsuite-embed-suites-search-bar-tag_list-container");
  var htmlCode = "";
  htmlCode += "<select id='xlsuite-embed-suites-search-bar-tag_list' name='tag_list'>";
  var tagListCollection = response.collection;
  htmlCode += "<option value=''>Tagged</option>";
  
  for (var i = 0; i < tagListCollection.length; i++) {
    htmlCode += tagXTemplate.apply(tagListCollection[i]);
  }
  
  htmlCode += "</select>";
  tagListContainer.innerHTML = htmlCode;
  tagListJsonRequest.removeScriptTag();
};

var generateSearchBar = function(){
  var searchBarButton = Ext.get("xlsuite-embed-suites-search-bar-button");
  if (searchBarButton){
    searchBarButton.addListener("click", function(el, event){
      replacePageNumWith(1);
      updateSuitesCatalogBody();
    });
  }

  var industriesContainer = document.getElementById("xlsuite-embed-suites-search-bar-industries-container");
  if (industriesContainer){
    industriesJsonRequest = new JsonRequestWithScriptTag({
      url:getAjaxRequestUrl()+"/admin/public/suites/industries.json",
      params: {callback: "generateSearchBarIndustriesSelection"}
    });
  }

  var mainThemesContainer = document.getElementById("xlsuite-embed-suites-search-bar-main_themes-container");
  if (mainThemesContainer){
    mainThemesJsonRequest = new JsonRequestWithScriptTag({
      url: getAjaxRequestUrl()+"/admin/public/suites/main_themes.json",
      params: {callback: "generateSearchBarMainThemesSelection"}
    });
  }

  var tagListContainer = document.getElementById("xlsuite-embed-suites-search-bar-tag_list-container");
  if (tagListContainer){
    tagListJsonRequest = new JsonRequestWithScriptTag({
      url:getAjaxRequestUrl()+"/admin/public/suites/tag_list.json",
      params: {callback: "generateSearchBarTagListSelection"}
    });
  }
};

var generatePaging = function(currentPage, pagesCount){
  var container = document.getElementById("xlsuite-embed-suites-paging");
  var htmlCode = "";
  if(pagesCount < 2){
    container.innerHTML = htmlCode;
    return;
  }
  var i = 1;
  for(i=1;i<=pagesCount;i++){
    htmlCode += "<a href='#' onclick='return false;' ";
    if (i==currentPage){
      htmlCode += "class='xlsuite-embed-suites-paging-number xlsuite-embed-suites-paging-current'>";
    }
    else{
      htmlCode += "class='xlsuite-embed-suites-paging-number'>";
    }
    htmlCode += (i + "</a>");
  }
  container.innerHTML = htmlCode;
  
  var pagingNumbers = Ext.DomQuery.select(".xlsuite-embed-suites-paging-number");
  for (var i = 0; i < pagingNumbers.length; i++) {
    Ext.EventManager.addListener(pagingNumbers[i], "click", function(event, el){
      replacePageNumWith(el.innerHTML);
      updateSuitesCatalogBody();
    });
  }
};

var suitesJsonRequest = null;

var replaceSuitesCatalogBody = function(response){
  var container = document.getElementById("xlsuite-embed-suites-selection");
  var suitesCollection = response.collection;
  var totalSuites = response.total;
  var pagesCount = response.pages_count;
  var htmlCode = "";
  var searchBarCode = "";
  var paginatorCode = "";
  if(totalSuites < 1){
    htmlCode += "No suite found";
  }
  else{
    htmlCode += xlSuiteEmbedBody(suitesCollection);
  }
  container.innerHTML = htmlCode;
  generatePaging(currentPageNum(), pagesCount);
  suitesJsonRequest.removeScriptTag();
};

var generateSuitesCatalogBody = function(parameters){
  parameters.callback = "replaceSuitesCatalogBody";
  suitesJsonRequest = new JsonRequestWithScriptTag({
    url:getAjaxRequestUrl()+"/admin/public/suites.json",
    params: parameters
  });
};

var currentPageNum = function(){
  return parseInt(document.getElementById("xlsuite-embed-suites-search-bar-page_num").value);
};

var currentPerPage = function(){
  return parseInt(document.getElementById("xlsuite-embed-suites-search-bar-per_page").value);
};

var replacePageNumWith = function(number){
  var el = document.getElementById("xlsuite-embed-suites-search-bar-page_num");
  el.value = number;
};

var replacePerPageWith = function(number){
  var el = document.getElementById("xlsuite-embed-suites-search-bar-per_page");
  el.value = number;
};

var getReferralDomain = function(){
  var el = document.getElementById("xlsuite-embed-suites-referral-domain");
  if(el)
    return el.innerHTML;
  else
    return "xlsuite.com";
};

var getAjaxRequestUrl = function(){
  return "http://" + getReferralDomain();
};

Ext.onReady(function(){
  generateSearchBar();
  updateSuitesCatalogBody();
});
