Ext.BLANK_IMAGE_URL = "/javascripts/extjs/resources/images/default/s.gif"

Ext.namespace('xl');

///// xl /////
function xl() { }

xl.dateFormat = 'F j, Y';    // January 1, 2008
xl.slashDateFormat = 'n/j/y';  // 1/1/08
xl.timeFormat = 'h:i A';    // 12:30 AM
xl.dateTimeFormat = xl.timeFormat + ' ' + xl.dateFormat;  // 12:30 AM January 1, 2008

xl.copyrightHTML = "<span class='copyright'>Site Design:<a class='producer' title='iXLd Media Inc.' href='http://www.ixld.com' target='_blank'>iXLd</a> | Powered by <a class='product' title='XL Suite' href='http://www.xlsuite.com' target='_blank'>XLsuite</a></span>"

xl.kToolbarBrownCSSColor = '#ded8d1'
xl.kDefaultColumnWidth = 200;
xl.kIconPath = '../images/icons/';
xl.viewport = null;
xl.tabPanel  = null;
xl.westPanel = null;
xl.centerPanel = null;
xl.maskedPanels = new Array();

// This is a shared object that
// simply holds temporary objects
// that should NOT be relied on
// except within a very small scope
xl.temp = function() { }

xl.partyPath = "admin/parties/(\\d+)";
//xl.routeToIdMap = new Hash({"/admin/folders[^/]":"file-manager-index" });
xl.routeToIdMap = new Hash({"/admin/folders[^/]*":"file-manager-index" });

// This holds a running list of all the tabs currently open.
// The key is the URL/URI which the tab displays.
// The value is the Ext.Panel itself
// Used by xl.createTab to remember which tabs are open
// so as to not reload a tab already open
xl.runningTabs = new Hash();  // This holds a running list of all the tabs currently open
xl.runningGrids = new Hash(); // This holds all running grids
xl.runningInsideTabs = new Hash(); // This holds all tab panels inside all tabs that are currently open
xl.title = new Hash();
xl.assetPanels = new Hash();
xl.imagePickerDataStores = new Hash();
xl.fileTreePanel = null;
xl.groupsTreePanel = null;

xl.tabManager = new XLManager({ base: 'tab' });

xl.log = function(msg) {
  if (typeof console != "undefined") {
    console.log(msg);
  }
}

xl.logXHRFailure = function(request, options) { 
  xl.log("FAILURE: " + request.responseText);
}

// This keeps track of the panels to call
// .expand(true) on after rendering the viewport.
// Used by AccordionStatePlugin to expand the active
// accordion panels referred to in the state manager.
xl.panelsToExpand = [];

///// xl.AccordionStatePlugin /////
// This simply finds out if its parent panel is
// the panel referred to by the state manager for
// being the last open accordion panel. If it is,
// the panel is added to the array of panels to expand,
// which are expanded *after* they and the viewport is rendered
xl.AccordionStatePlugin = function(accordionStatePrefix) {
  this.activeItemIdKey = accordionStatePrefix + '.activeItem.id';

  this.init = function(panel) {
    if (panel.id == Ext.state.Manager.get(this.activeItemIdKey)) {
      xl.panelsToExpand.push(panel);
    }

  };
}

xl.formatDate = function(value){
  if (typeof value != "object"){
    return value;
  }
  return value ? value.dateFormat('d/m/Y') : '';
}

xl.closeTabPanel = function(id){
  xl.tabPanel.remove(id);
}

// Simply close the tab with the correct id
xl.closeTabWithId = function(id) {
  var panel = xl.tabManager.get(id);
  if (panel) {
    panel.close();
    return true;
  } else return false;
}

// The following function is used to close all existing tabs but
// one with the same id as the specified source
xl.closeOtherTabs = function(source) {
  xl.runningTabs.each(function(pair){
    if (pair.key != source) {
      xl.tabPanel.remove(pair.value);
    }
  });
}

xl.closeTabs = function(regexp_string) {
  xl.runningTabs.each(function(pair){
    if ( pair.key.match(new RegExp(regexp_string, "i")) ){
      xl.tabPanel.remove(pair.value);
    }
  });
}

xl.refreshIframe = function(id) {
  var iframe = $(id);
  if (iframe) {
    iframe.contentWindow.window.location.reload(true);
  }
}

xl.openNewTabPanel = function(tabPanelId, ajxrUrl, ajxrParams, activeTabId) {
  var panel = xl.runningTabs.get(tabPanelId);
  var insideTab = xl.runningInsideTabs.get(tabPanelId);
  var params = ajxrParams || {};
  
  if (panel) {
    panel.show();
    if (insideTab){
      if (activeTabId){
        insideTab.setActiveTab(activeTabId);
      }
    }
  } else {
    xl.tabPanel.el.mask("Loading...");
    Ext.Ajax.request({
      url: ajxrUrl,
      params: ajxrParams,
      method: "GET",
      callback: function(options, success, response){
        xl.tabPanel.el.unmask();
      }
    });
  }
}

xl.resizeTabPanel = function() {
  xl.tabPanel.setWidth(xl.centerPanel.getInnerWidth());
  xl.tabPanel.setHeight(xl.centerPanel.getInnerHeight());
  Ext.DomQuery.select('iframe').each(function(iframe){
    // iframe is an HTMLElement, but we need an Ext.Element
    iframe = Ext.Element.get(iframe);
    // If null, the iframe does not have an Editor Wrapper parent DIV,
    // otherwise, it does and should not be affected
    if (iframe.findParent('div.x-html-editor-wrap') == null) {
      var iframeTemp = Ext.get(iframe.id);
      iframeTemp.setWidth(xl.centerPanel.getInnerWidth());
      iframeTemp.setHeight(xl.centerPanel.getInnerHeight() - xl.centerPanel.getBottomToolbar().getSize().height - 14);
    }
  });
  var grid = null;
  xl.runningGrids.each(function(pair){
    grid = pair.value;
    try{
      if (grid.emailGridHeight) {
        grid.setHeight(grid.emailGridHeight);
      }
      else {
        //grid.setHeight(xl.centerPanel.getInnerHeight() - xl.centerPanel.getBottomToolbar().getSize().height - 14);
        if (!grid.doNotSyncSize) {
          grid.syncSize();
        }
      }
    }
    catch(err){
      if(!grid)
        xl.runningGrids.unset(pair.key);
      xl.log("resize tab panel error");
    }
  });
  if (xl.viewport) { xl.viewport.render(); };
};

xl.generateIframeIdFromSource = function(source) {
  var iframeId = xl.routeToIdMap[source];  
  if (iframeId) {
    return iframeId;
  };
  xl.routeToIdMap.each(function(pair){
    if (source.match(new RegExp(pair.key, "i"))) {
      iframeId = pair.value;
    }
  });
  return iframeId;
}

xl.sendDefaultGetAjaxRequest = function(source) {
  new Ajax.Request(source, {asynchronous:true, evalScripts:true, method:'get'});
}

xl.createTabAsDiv = function(source) {
  var mappedId = xl.generateIframeIdFromSource(source);
  if (!mappedId) mappedId = source;

  var panel = xl.runningTabs.get(mappedId);
  
  if (!panel) {
    
    // This Updater makes the asynchronous call for us
    // then replaces the updaterDump DIV's innerHTML with the responseText
    var updater = new Ext.Updater(Ext.get('updaterDump'));
    updater.update(
      source, '',
      // Everything must be done in this callback simply because the data
      // from the async call isn't readily available.
      function(element, success, request) {
        if (!success) alert('The retrieval of the page failed.');
        
        // Set up underbar links
        var other_links_container = "<span id='" + mappedId + "-other-links'></span>";
        var links_container       = "&nbsp;&nbsp;&nbsp;<span id='" + mappedId +"-link'></span>";
        var close_other_tabs_link = "&nbsp;&nbsp;&nbsp;<span><a href=\"#\" onClick=\"xl.closeOtherTabs('"+ mappedId +"'); return false;\">Close other tabs</a></span>";
    
        // Then create and setup wrapperPanel
        var wrapperPanel = new Ext.Panel({
          id: mappedId,
          title: "Loading...",
          titlebar: true,
          tbar: new Ext.Toolbar({
            style: 'background-color: ' + xl.kToolbarBrownCSSColor + ';',
            items: [ other_links_container + links_container + close_other_tabs_link ]
          }),
          layout: 'fit',
          autoWidth: true
        });
      
      xl.log('XHttpRequest was successful! Retrieving SCRIPT tag...');
      
      var scriptTag = Ext.get('constructor'); // First get the actual tag holding the code...
      var resultSet;
      
      try {
        xl.log("Evaluating contents of SCRIPT tag in try/catch...");      
        eval(scriptTag.dom.text); // ...Then evaluate that code...

        xl.log("Evaluated! Calling constructor() in try/catch...");
        
        resultSet = constructor(); // ...Call that constructor function...
      } catch (error) {
        xl.log('Caught error while working with constructor():');
        xl.log(error);
      }
      
      xl.log('Called constructor()! Working with resultSet outside try/catch: ');
      xl.log(resultSet);
      wrapperPanel.add(resultSet.panel); // ...And add the panel to display to the tab
      
      xl.log('Added returned Panel to wrapperPanel');
      wrapperPanel.setTitle(resultSet.title);
      
      xl.log('Set title of wrapperPanel to "' + resultSet.title + '"');
      
      // Catch the panel when it's closed
      wrapperPanel.on('destroy', function() {
        // Explicitly destroy specified remnants
        if (resultSet.remnants) {
          resultSet.remnants.each(function(o) {
            o.destroy();
          });
        }
        xl.runningTabs.unset(mappedId);
      });
  
      // No idea what this section does...
      xl.title.set(mappedId, "Record Dashboard...");
      
      wrapperPanel.on('show', function(){
        xl.viewport.render();
        //xl.resizeTabPanel();
        
        //xl.setEastTitle(xl.title[mappedId], source);
        
        //parent.$('current-displayed-iframe-source').value = source;
        //$('recordMessagesPanel').childElements().each(function(e) { e.hide(); });
        //$('recordFilesPanel').childElements().each(function(e) { e.hide(); });
        
        /*
        if(source.match(/parties\/\d+/)){
          acc_names = $w('messages files payments');
          acc_names.each(function(s){
            div = "party_".concat(source.match(/\d+(?!parties\/)/), s);
            if(parent.$('div')){
              parent.$(div).show();
            }
            else{
              func_name = "record"+s.capitalize()+"Refresh";
              ("<script>parent."+func_name+"('"+source+"'.match(/\\d+(?!parties\\/)/));</script>").evalScripts();
            }
          });
        }
        else if(source == "/admin/parties"){
          parent.recordMessagesRefresh(parent.$('contact-list-ids').value);
          parent.recordFilesRefresh(parent.$('contact-list-ids').value);
          parent.recordPaymentsRefresh(parent.$('contact-list-ids').value);
        }
        */
      }); // end wrapperPanel.on
    
      xl.tabPanel.add(wrapperPanel).show();  // Add the wrapper Panel to the TabPanel in the main layout
      xl.runningTabs.set(mappedId, wrapperPanel);
      xl.tabManager.add(wrapperPanel, resultSet.tabId);
      
      // This is to tell the viewport it's been altered
      // so the bottommost bbar doesn't get lost and the page
      // shows immediately
      xl.viewport.render();
      
      // A page can specify a callback function to call
      // after the page has been rendered. Useful for
      // calling functions that only apply when rendered
      if (resultSet.callback) {
        try {
          xl.log('A constructor callback has been specified. Calling inside try/catch...');
          resultSet.callback();
        } catch (error) {
          xl.log('Error caught while executing constructor callback:');
          xl.log(error);
        }
      }
      
      // Make its toolbar brown -- purely cosmetic!
      //wrapperPanel.getTopToolbar().getEl().addClass('bg-brown');
  
      // Unset the constructor function and remove
      // the SCRIPT tag from the DOM so the next tab
      // can be created
      delete window.constructor;
      scriptTag.remove();
      
    }); // end callback
  } else {  // The tab is already open
    // Since the panel's already in the DOM,
    // we don't want to reload it so just switch back to that tab
    panel.show();
  }  
} // end xl.createTabAsDiv

// This is what is called whenever the user navigates
// to a new page. It checks if the requested page is
// already open, and if it is, it switches to it.
// Otherwise, it opens a new tab in the central TabPanel
xl.createTab = function(source, defaultId) {
  
  // First look for an IFRAME with the id of source
  var mappedIframeId = xl.generateIframeIdFromSource(source);
  if (!mappedIframeId) {
    mappedIframeId = source;  
  }
  if (defaultId != undefined) {
    mappedIframeId = defaultId;
  }
  
  var iframe = Ext.get(mappedIframeId);
  
  var title = source.sub("http://","");
  
  if ( source.match(new RegExp(xl.partyPath, "i")) ){
    var party_id = RegExp.$1;
    Ext.DomQuery.select("iframe").each(function(ifrm){
      if ( source == ifrm.id)
        xl.runningTabs.get(source).show();
      else if ( ifrm.id.match(new RegExp("admin/parties/" + party_id, "i")) ){
        xl.closeTabs(ifrm.id);
      };
    });
  };
  
  if (iframe == null) {  // The page has never been opened before
    // Create, setup and attach the iframe HTMLIFRAMEObject
    iframe = document.createElement('iframe');
    iframe.src = source;
    iframe.id = mappedIframeId;
    iframe.scrolling = 'auto';
    document.body.appendChild(iframe);

    //iframe = new Ext.Element("<iframe id='" + source + "' src='" + source + "' scrolling='no'/>");
    //iframe.appendTo(Ext.getBody());
    // Now iframe is an Ext.Element object
    iframe = Ext.get(mappedIframeId);
    iframe.setHeight(Ext.getBody().getHeight()-107);

    // Then create and setup the Panel
    var newPanel = new Ext.Panel({
      id: mappedIframeId + "-panel",
      title: "Loading...",
      contentEl: iframe,
      titlebar: true,
      ctCls: 'brown3pxBorder'
    });

    // Remove the tabpanel object on the runningTabs
    newPanel.on('destroy', function(pn) {
      if (source == "/admin/parties"){
        parent.$('contact-list-ids').value = "";
      }
      xl.runningTabs.unset(mappedIframeId);
    });


    xl.title.set(mappedIframeId, "Record Dashboard...");
    newPanel.on('show', function(pn){
      xl.resizeTabPanel();
      xl.setEastTitle(xl.title.get(mappedIframeId), source);
      parent.$('current-displayed-iframe-source').value = source;
      parent.$('recordMessagesPanel').childElements().each(function(e){e.hide();});
      parent.$('recordFilesPanel').childElements().each(function(e){e.hide();});
      if(source.match(/parties\/\d+/)){
        acc_names = $w('messages files payments');
        acc_names.each(function(s){
          div = "party_".concat(source.match(/\d+(?!parties\/)/), s);
          if(parent.$('div')){
            parent.$(div).show();
          }
          else{
            func_name = "record"+s.capitalize()+"Refresh";
            ("<script>parent."+func_name+"('"+source+"'.match(/\\d+(?!parties\\/)/));</script>").evalScripts();
          }
        });
      }
      else if(source == "/admin/parties"){
        parent.recordMessagesRefresh(parent.$('contact-list-ids').value);
        parent.recordFilesRefresh(parent.$('contact-list-ids').value);
        parent.recordPaymentsRefresh(parent.$('contact-list-ids').value);
      }
    });

    xl.tabPanel.add(newPanel).show();
    xl.runningTabs.set(mappedIframeId, newPanel);

    iframe.on("load", function(e) {
      if ( xl.runningTabs.get(mappedIframeId) && xl.runningTabs.get(mappedIframeId).title.match(new RegExp("^loading", "i")) ) {
        xl.runningTabs.get(mappedIframeId).setTitle(title);
      }
    });
    
    // This is to tell the viewport it's been altered
    // so the bottommost bbar doesn't get lost
    xl.viewport.render();
  } else {
    // Since the IFRAME's already in the DOM,
    // we don't want to reload it...
    var panel = xl.runningTabs.get(mappedIframeId);

    // ... so just switch back to that tab
    panel.show();
  }
} // end xl.createTab

xl.generateSimpleHttpJSONStore = function(config) {
  var mappings = config.fieldNames.collect(function(fieldName) {
    return {name: fieldName};
  });
  
  var reader = new Ext.data.JsonReader(
    {totalProperty: "total", root: "collection"},
    new Ext.data.Record.create(mappings)
  );

  var store = new Ext.data.Store({
    proxy: new Ext.data.HttpProxy(new Ext.data.Connection({
      url: config.url,
      method: (config.method || 'get')
    })),
    reader: reader,
    autoLoad: (config.autoLoad)
  })
  
  if (config.onLoad) { store.on('load', config.onLoad, this, {single:true}); }
  if (config.doLoad) { store.load(); }

  return store;
}

xl.generateMemoryArrayStore = function(config) {
  var record = new Ext.data.Record.create(config.mappings);
  var reader;
  
  if (config.idPos)
    reader = new Ext.data.ArrayReader({id: config.idPos}, record);
  else
    reader = new Ext.data.ArrayReader({}, record);

  var store = new Ext.data.Store({
    proxy: new Ext.data.MemoryProxy(config.records),
    reader: reader
  });
  
  if (config.onLoad) { store.on('load', config.onLoad); }
  if (config.doLoad) { store.load(); }
  
  return store;
}

xl.generateIdStringRecordsForRange = function(range, step, config) {
  var step = step || 1;
  /* Possible configs:
   * pad (Number): length for Number.toPaddedString
   */
  var config = config || {};
  var counter = 0;
  
  // If range = $R(1,12), set = [[0, '1'], ... , [11, '12']]
  // If range = $R(1,60) and step = 5, set = [[0, '5'], ... , [59, '60']]
  var set = range.collect(function(x) {
    if ( (x % step) == 0) {
      var s = x.toString();
      if (config.pad) s = x.toPaddedString(config.pad);
      counter++;
      return [counter, s];
    } else {
      // Put falses in the places where the modulus operation fails
      return false;
    }
  });
  
  return set.without(false);  // Get rid of those falses
}

xl.elapsedTimeAsWords = function(secs) {
  var s = '';
  if (secs / 60 >= 1) {
    s = Math.floor((secs / 60)) + ' minute(s) ' + (secs % 60) + ' seconds';
  } else {
    s = secs + ' seconds';
  }
  
  return s;
};

xl.createIntervalForFutureUpdater = function(url, refreshIntervalSecs) {
  var secondsElapsed = 0;
  var intervalId = setInterval(function() {
    secondsElapsed = xl.updateFuturePage(url, refreshIntervalSecs, secondsElapsed, intervalId);
  }, refreshIntervalSecs * 1000);
};

xl.updateFuturePage = function(url, refreshIntervalSecs, secondsElapsed, intervalId) {
  secondsElapsed += refreshIntervalSecs;
  
  Ext.Ajax.request({
     url: url,
     success: function(response, options) {
       var future = Ext.util.JSON.decode(response.responseText);
       var suffix = '_for_future_' + future.id;
       //var fields = ['status', 'progress', 'elapsed'];
       if (typeof future != 'undefined') {
         Element.show("throbber_for_future_" + future.id);
         Ext.get('status' + suffix).update(future.status);
         Ext.get('progress' + suffix).update(future.progress);
         Ext.get('elapsed' + suffix).update(xl.elapsedTimeAsWords(secondsElapsed));
         //page.replace_html "x_future_error", :partial => "error", :collection => @errors
         
         if (future.isCompleted) {
           Element.hide("throbber_for_future_" + future.id);
           xl.log('Completed Future #' + future.id);
           //TODO: need to provide a flow after this
           xl.openNewTabPanel('results_from_future_' + future.id + 'nil', future.returnTo);
           //close this tab
           clearInterval(intervalId);
         }  // end if
       }  // end if
     }, // end success
     failure: function(response, options){
       xl.logXHRFailure;
       clearInterval(intervalId);
     }
  });
  
  return secondsElapsed;
};

xl.updateStatusBar = function(string){
  $("status-bar-notifications").innerHTML = string;
};

xl.fitToOwnerCt = function(cpt){
  var size = cpt.ownerCt.getSize();
  cpt.setSize(size.width, size.height);
};

xl.fitToOwnerCtHeight = function(cpt){
  cpt.setHeight(cpt.ownerCt.getSize().height);
};

xl.fitToOwnerCtWidth = function(cpt){
  cpt.setWidth(cpt.ownerCt.getSize().width)
};

/**
*
* URL encode / decode
* http://www.webtoolkit.info/
*
**/
var Url = {

    // public method for url encoding
    encode : function (string) {
        return escape(this._utf8_encode(string.toString()));
    },

    // public method for url decoding
    decode : function (string) {
        return this._utf8_decode(unescape(string));
    },

    // private method for UTF-8 encoding
    _utf8_encode : function (string) {
        string = string.replace(/\r\n/g,"\n");
        var utftext = "";

        for (var n = 0; n < string.length; n++) {

            var c = string.charCodeAt(n);

            if (c < 128) {
                utftext += String.fromCharCode(c);
            }
            else if((c > 127) && (c < 2048)) {
                utftext += String.fromCharCode((c >> 6) | 192);
                utftext += String.fromCharCode((c & 63) | 128);
            }
            else {
                utftext += String.fromCharCode((c >> 12) | 224);
                utftext += String.fromCharCode(((c >> 6) & 63) | 128);
                utftext += String.fromCharCode((c & 63) | 128);
            }

        }

        return utftext;
    },

    // private method for UTF-8 decoding
    _utf8_decode : function (utftext) {
        var string = "";
        var i = 0;
        var c = c1 = c2 = 0;

        while ( i < utftext.length ) {

            c = utftext.charCodeAt(i);

            if (c < 128) {
                string += String.fromCharCode(c);
                i++;
            }
            else if((c > 191) && (c < 224)) {
                c2 = utftext.charCodeAt(i+1);
                string += String.fromCharCode(((c & 31) << 6) | (c2 & 63));
                i += 2;
            }
            else {
                c2 = utftext.charCodeAt(i+1);
                c3 = utftext.charCodeAt(i+2);
                string += String.fromCharCode(((c & 15) << 12) | ((c2 & 63) << 6) | (c3 & 63));
                i += 3;
            }

        }

        return string;
    }

}
