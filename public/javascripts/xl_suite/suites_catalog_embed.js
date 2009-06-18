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

var xlCurrentCounter = 1; //default to bottom form
var setXlCounter = function(counter){
  xlCurrentCounter = counter;
}

var slideDownFreeDetails = function(suiteId){
  var freeDetails = Ext.get("suite-free-details-"+suiteId)
  if(!freeDetails.isVisible())
    freeDetails.slideIn();
}

var slideDownProDetails = function(suiteId){
  var proDetails = Ext.get("suite-pro-details-"+suiteId)
  if(!proDetails.isVisible())
    proDetails.slideIn();
}

var toggleInstallForm = function(suiteId){
  var installButton = document.getElementById("xlsuite-install-button-"+suiteId);
  var installLink = document.getElementById("xlsuite-install-link-"+suiteId);
  if(installButton.value=="INSTALL"){
    installButton.value = "CANCEL";
    installLink.innerHTML = "CANCEL";
    displayInstallForm(suiteId);
  }
  else if(installLink.innerHTML=="INSTALL"){
    installLink.innerHTML = "CANCEL";
    installButton.value = "CANCEL";
    displayInstallForm(suiteId);
  }
  else if(installButton.value=="CANCEL"){
    installButton.value = "INSTALL";
    installLink.innerHTML = "INSTALL";
    hideInstallForm(suiteId);
  }
  else if((installLink.innerHTML=="CANCEL")){
    installLink.innerHTML = "INSTALL";
    installButton.value = "INSTALL";
    hideInstallForm(suiteId);
  }
}

var displayInstallForm = function(suiteId){
  var installFormId = "xlsuite-install-form-";
  if(xlCurrentCounter==0){
    installFormId = installFormId + "top-"
  }
  var installForm = Ext.get(installFormId+suiteId);
  installForm.setHeight(40);
  installForm.show();
}

var hideInstallForm = function(suiteId){
  var installFormId = "xlsuite-install-form-";
  var installForm = Ext.get(installFormId+suiteId);
  installForm.hide();
  installForm.setHeight(0);
  installFormId = "xlsuite-install-form-top-";
  installForm = Ext.get(installFormId+suiteId);
  installForm.hide();
  installForm.setHeight(0);
}

var xlsuiteValidEmail = false;
var xlsuiteValidDomainName = false;
var currentSuiteId = null;

var doEmailCheck = function(suiteId){
  xlsuiteValidEmail = false;
  currentSuiteId = suiteId;
  var emailAddressId = "account-signup-email-address-";
  var emailAddressStatusId = "account-signup-email-checker-status-";
  if(xlCurrentCounter==0){
    emailAddressId = emailAddressId + "top-";
    emailAddressStatusId = emailAddressStatusId + "top-";
  }
  var emailAddress = document.getElementById(emailAddressId + suiteId.toString()).value;
  var emailAddressStatus = document.getElementById(emailAddressStatusId + suiteId.toString());
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
  var domainNameId = 'account-signup-domain-name-checker-';
  if(xlCurrentCounter==0){
    domainNameId = domainNameId + "top-";
  }
  var domainName = document.getElementById(domainNameId+suiteId.toString()).value + "." + getReferralDomain();
  suitesJsonRequest = new JsonRequestWithScriptTag({
    url:getAjaxRequestUrl()+"/admin/domains/validate_name",
    params: {callback:"updateDomainNameCheckerStatus", name:domainName}
  });
}

var updateDomainNameCheckerStatus = function(response){
  var domainNameStatusId = "account-signup-domain-checker-status-";
  if(xlCurrentCounter==0){
    domainNameStatusId = domainNameStatusId + "top-"
  }
  var domainNameStatus = document.getElementById(domainNameStatusId + currentSuiteId.toString());
  if(response.valid){
    domainNameStatus.innerHTML = "Available";
    xlsuiteValidDomainName = true;
  }
  else{
    domainNameStatus.innerHTML = response.errors;
    xlsuiteValidDomainName = false;
  }
  disableEnableSubmitButton();
  var domainNameCheckerId = 'account-signup-domain-name-checker-';
  if(xlCurrentCounter==0){
    domainNameCheckerId = domainNameCheckerId + "top-"
  }
  var domainName = document.getElementById(domainNameCheckerId+currentSuiteId.toString()).value + "." + getReferralDomain();
  
  var domainNameId = "account-signup-domain-name-";
  if(xlCurrentCounter==0){
    domainNameId = domainNameId + "top-"
  }
  document.getElementById(domainNameId+currentSuiteId.toString()).value = domainName;
}

var disableEnableSubmitButton = function(){
  var submitButtonId = "account-signup-submit-button-";
  if(xlCurrentCounter==0){
    submitButtonId = submitButtonId + "top-";
  }
  var submitButton = document.getElementById(submitButtonId+currentSuiteId.toString());
  if(xlsuiteValidEmail && xlsuiteValidDomainName){
    submitButton.disabled = false;
  }
  else{
    submitButton.disabled = true;
  }
}

var xlSuiteEmbedBody = function(suitesCollection){
  var htmlCode = "";
  var tAffiliateId = "";
  if(typeof(xlsuiteAffiliateId) == "string"){
    tAffiliateId = xlsuiteAffiliateId;
  }
  var suiteXTemplate = new Ext.XTemplate(
    "<li class='xlsuite-embed-suite-item'>",
      '<h2><a href="#" title="" target="_blank">{name}</a><a class="xlsuite_install_button" href="#" onClick="setXlCounter(0);toggleInstallForm({id});return false;" id="xlsuite-install-link-{id}" class="xlsuite_install_button">INSTALL</a></h2>',
      '<div class="suite-install"><a name="install"></a>',
        "<form style='display:none;' id='xlsuite-install-form-top-{id}' class='xlsuite-embed-suite-item-form' action='http://", getReferralDomain(), "/admin/accounts' method='post'>",
          "<input type='hidden' name='account[referral_domain]' value='", getReferralDomain(), "' />",
          "<input type='hidden' name='account[suite_id]' value='{id}' />",
          "<input type='hidden' name='account[affiliate_id]' value='" + tAffiliateId + "' />",
          "<input type='hidden' value='' name='domain[name]' autocomplete='off' id='account-signup-domain-name-top-{id}'/>",
          "<span id='account-signup-domain-checker-status-top-{id}' class='account-signup-domain-checker-status'></span>",
          "<input class='account_signup_domain_name_check' onblur='setXlCounter(0);doDomainNameCheck({id});return false;' onfocus='setXlCounter(0);this.select();return false;' value='choose a subdomain' name='' autocomplete='off' id='account-signup-domain-name-checker-top-{id}'/>",
          '<span class="domain"> .'+getReferralDomain()+' </span><br />',
          "<span id='account-signup-email-checker-status-top-{id}' class='account-signup-email-checker-status'></span>",
          '<input class="account_signup_email_check" onblur="setXlCounter(0);doEmailCheck({id});return false;" onkeyup="setXlCounter(0);doEmailCheck({id});return false" onfocus="this.select();return false;" value="enter your email" name="email[email_address]" autocomplete="off" id="account-signup-email-address-top-{id}"/>',
          "<input class='account_signup_button' id='account-signup-submit-button-top-{id}' disabled='true' type='submit' value='SUBMIT' />",
        "</form>",
      '</div>',
      '<dl class="xlsuite-embed-suite-item-details">',
        '<dt>Description</dt>',
        '<dd>{description}</dd>',
        '<dt>Features</dt>',
        '<dd>{features_list}</dd>',
        '<dt>Installed</dt>',
        '<dd>{installed_count}</dd>',
        '<dt>Tags</dt>',
        '<dd>{tag_list}</dd>',
        '<dt>Designer</dt>',
        '<dd>{designer_name}</dd>',
        '<!--<dt>FEES</dt>',
        '<dd>',
          '<ul>',
            '<li><b>Advertising Supported Version</b>  -  <a href="javascript:slideDownFreeDetails({id})"><span class="free">Free</span></a></li>',
            '<li id="suite-free-details-{id}" style="display:none;">',
              '<p>',
                "At the end of the 60 days if you haven't gone pro, we will revert to the base suite and insert our ads into the suite. <br />",
                'You may lose some of the customizations you did to your pages.<br />',
                "You are welcome to continue using it as a subdomain for as long as you'd like for free.<br />",
                'You can always "go pro" at a later date once you have grown your online business.<br />',
                'Click "Install" to start your installation process now.',
              '</p>',
            '</li>',
            '<li><a href="javascript:slideDownProDetails({id})"><span class="pro">Pro Version</span></a> (Click for details)</li>',
            '<li id="suite-pro-details-{id}" style="display:none;">',
              '<p>Installation Fee: {setup_fee}<br/>Subscription Fee: {subscription_fee}/month</p>',
            '</li>',
          '</ul>',
        '</dd>-->',
      '</dl>',
      "<div class='xlsuite-embed-suite-more-info'>",
        '<div>',
          '<a href="{demo_url}" title="" target="_blank"><img src="{main_image_url}?size=medium" alt="" title="" class="xlsuite-embed-suite-item-main-image"/></a>',
          '<h3>60 DAY FREE TRIAL</h3>',
          '<p class="clear" />',
          '<p>Choose a subdomain and start your FREE TRIAL. You\'ll have a full featured site up in minutes, not months!<br />', 
            'When your site is ready, it\'s a snap to map your own domain name to it and go LIVE without having to move anything!',
          "<input class='xlsuite_install_button' id='xlsuite-install-button-{id}' type='submit' value='INSTALL' onclick='setXlCounter(1);toggleInstallForm({id}); return false;'>",
        '</div>',
      "</div>",
      '<div class="suite-install"><a name="install"></a>',
        "<form style='display:none;' id='xlsuite-install-form-{id}' class='xlsuite-embed-suite-item-form' action='http://", getReferralDomain(), "/admin/accounts' method='post'>",
          "<input type='hidden' name='account[referral_domain]' value='", getReferralDomain(), "' />",
          "<input type='hidden' name='account[suite_id]' value='{id}' />",
          "<input type='hidden' name='account[affiliate_id]' value='" + tAffiliateId + "' />",
          "<input type='hidden' value='' name='domain[name]' autocomplete='off' id='account-signup-domain-name-{id}'/>",
          "<span id='account-signup-domain-checker-status-{id}' class='account-signup-domain-checker-status'></span>",
          "<input class='account_signup_domain_name_check' onblur='setXlCounter(1);doDomainNameCheck({id});return false;' onfocus='setXlCounter(1);this.select();return false;' value='choose a subdomain' name='' autocomplete='off' id='account-signup-domain-name-checker-{id}'/>",
          '<span class="domain"> .'+getReferralDomain()+' </span><br />',
          "<span id='account-signup-email-checker-status-{id}' class='account-signup-email-checker-status'></span>",
          '<input class="account_signup_email_check" onblur="setXlCounter(1);doEmailCheck({id});return false;" onkeyup="setXlCounter(1);doEmailCheck({id});return false" onfocus="this.select();return false;" value="enter your email" name="email[email_address]" autocomplete="off" id="account-signup-email-address-{id}"/>',
          "<input class='account_signup_button' id='account-signup-submit-button-{id}' disabled='true' type='submit' value='SUBMIT' />",
        "</form>",
      '</div>',
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
  var el = document.getElementById("xlsuite-embed-suites-search-bar-page_num");
  if(el){
    return parseInt(el.value);
  }
  else{
    return xlsuiteEmbedSuitesCurrentPageNum;
  }
};

var currentPerPage = function(){
  var el = document.getElementById("xlsuite-embed-suites-search-bar-per_page");
  if(el) {
    return parseInt(el.value);
  }
  else{
    return xlsuiteEmbedSuitesPerPage;
  }
};

var replacePageNumWith = function(number){
  var el = document.getElementById("xlsuite-embed-suites-search-bar-page_num");
  if(el){
    el.value = number;
  }
  else{
    xlsuiteEmbedSuitesCurrentPageNum = number;
  }
};

var replacePerPageWith = function(number){
  var el = document.getElementById("xlsuite-embed-suites-search-bar-per_page");
  if(el){
    el.value = number;
  }
  else{
    xlsuiteEmbedSuitesPerPage = number;
  }
};

var getReferralDomain = function(){
  var el = document.getElementById("xlsuite-embed-suites-referral-domain");
  if(el)
    return el.innerHTML;
  else{
    if(typeof(xlsuiteEmbedSuitesReferralDomain) == "undefined")
      return "xlsuite.com";
    else{
      return xlsuiteEmbedSuitesReferralDomain;
    }
  }  
};

var getAjaxRequestUrl = function(){
  return "http://" + getReferralDomain();
};

Ext.onReady(function(){
  generateSearchBar();
  updateSuitesCatalogBody();
});
