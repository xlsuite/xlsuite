Ext.onReady(function() {
  // initialize state manager, we will use cookies
  Ext.state.Manager.setProvider(new Ext.state.CookieProvider());

  // initialize QuickTips
  Ext.QuickTips.init();

  var iframe = parent.$('layout-center-list-iframe');
  // mail refresh button
  var unreadMailRefreshButton = new Ext.Toolbar.Button({
    text: 'Refresh',
    cls: "mailRefreshbutton",
    handler: function(){
      unreadMailRetrieve();
    }
  });

  //refresh unread messages
  unreadMailRefresh = function(){
    new Ajax.Request("/admin/emails/show_unread_emails", {asynchronous:true, evalScripts:true, method:'get', 
      onCreate: function(){$('mail-panel-title').update("Unread Messages Loading...");}});
  };

  //refresh sent and read emails
  sentReadMailRefresh = function(){
    new Ajax.Request("/admin/emails/show_sent_and_read_emails", {asynchronous:true, evalScripts:true, method:'get',
       onCreate: function(){$('my-history-panel-title').update("My History Loading...");}, 
       onComplete: function(){$('my-history-panel-title').update("My Recent History");}});
  };

  recordMessagesRefresh = function(ids){
    new Ajax.Request('/admin/emails/show_all_emails?ids='+ids, {asynchronous:true, evalScripts:true, method:'get',
       onCreate: function(){$('record-messages-title').update("Messages Loading...");}, 
       onComplete: function(){$('record-messages-title').update("Messages");}});
  };

  recordFilesRefresh = function(ids){
    new Ajax.Request('/admin/assets/show_all_records_files?ids='+ids, {asynchronous:true, evalScripts:true, method:'get',
       onCreate: function(){$('record-files-title').update("Files Loading...");}, 
       onComplete: function(){$('record-files-title').update("Files");}});
  };

  recordPaymentsRefresh = function(ids){
    /* DO NOTHING for now
    new Ajax.Request('/admin/payments/show_all_records_payments?ids='+ids, {asynchronous:true, evalScripts:true, method:'get',
       onCreate: function(){$('record-payments-title').update("Payments Loading...");}, 
       onComplete: function(){$('record-payments-title').update("Payments");}}); */
  };
  
  myFeedsRefresh = function(){
    new Ajax.Request('/admin/feeds/refresh_my_feeds', {asynchronous:true, evalScripts:true, method:'get',
       onCreate: function(){$('feeds-panel-title').update("My Feeds Loading...");}, 
       onComplete: function(){$('feeds-panel-title').update("My Feeds");}});
  };
  
  myFeedsShow = function(){
     new Ajax.Request('/admin/feeds/show_feeds', {asynchronous:true, evalScripts:true, method:'get',
       onCreate: function(){$('feeds-panel-title').update("My Feeds Loading...");}, 
       onComplete: function(){$('feeds-panel-title').update("My Feeds");}});
     xl.westPanel.syncSize(); 
  };
  
  myEmailLabelsRefresh = function(){
    new Ajax.Request('/admin/email_labels/show', {asynchronous:true, evalScripts:true, method:'get',
       onCreate: function(){$('email_labels-panel-title').update("My Email Labels Loading...");}, 
       onComplete: function(){$('email_labels-panel-title').update("My Email Labels");}});
     xl.westPanel.syncSize(); 
  };

  xl.westPanel = new Ext.Panel({
    region: 'west',
    title: "<div class='left-console-title'><br/>My Dashboard</div>",
    titlebar: true,
    collapsible: true,
    collapseMode: 'mini',
    animCollapse: true,
    split: true,
    cls: "westPanel",
    width: xl.kDefaultColumnWidth,

    layout: 'accordion',
    layoutConfig: {animate: true},
    defaults: { plugins: xl.AccordionStatePlugin('westPanel') },
    items: [
      {
      id: 'westPanel-quickEntryPanel',
        title: 'Quick Entry',
        contentEl: 'quickEntryPanel'
      },{
      id: 'westPanel-mailPanel',
        title: "<span id='mail-panel-title'>My Recent Unread Messages</span>",
        contentEl: 'mailPanel',
        tools: [{
          id:'refresh',
          on:{
            click: function(){
              unreadMailRetrieve();
            }
          }
        }]
      },{
      id: 'westPanel-historyPanel',
        title: '<span id="my-history-panel-title">My Recent History</span>',
        contentEl: 'myHistoryPanel',
        tools: [{
          id:'refresh',
          on:{
            click: function(){
              sentReadMailRefresh();
            }
          }
        }]
      },
      {
        id: 'westPanel-emailLabelsPanel',
        title: "<span id='email_labels-panel-title'>My Email Labels</span>",
        collapsible: true,
        animCollapse: true,
        contentEl: "myEmailLabelsPanel", 
        tools: [{
          id:'refresh',
          on:{
            click: function(){
              myEmailLabelsRefresh();
            }
          }
        }]
      },
      {
      id: 'westPanel-feedsPanel',
        title: '<span id="feeds-panel-title">My Feeds</span>',
        contentEl: 'myFeedsPanel',
        tools: [{
          id:'refresh',
          on:{
            click: function(){
              myFeedsShow();
            }
          }
        }]
      },{
      id: 'westPanel-savedSearchesPanel',
        title: 'My Saved Searches',
        contentEl: 'mySavedSearchesPanel'
      }
    ]
  });

  xl.eastPanel = new Ext.Panel({
    region: 'east',
    title: "<div class='right-console-title'>Record Dashboard</div>",
    id: "eastPanel",
    titlebar: true,
    collapsible: true,
    collapseMode: 'mini',
    animCollapse: true,
    split: true,
    cls: "eastPanel",
    width: xl.kDefaultColumnWidth,

    layout: 'accordion',
    layoutConfig: {animate: true},
    defaults: { plugins: xl.AccordionStatePlugin('eastPanel') },
    items: [
      {
        id: 'eastPanel-messagesPanel',
        title: "<span id='record-messages-title'>Messages</span>",
        collapsible: true,
        animCollapse: true,
        contentEl: "recordMessagesPanel",
        tools: [{
          id:'refresh',
          on:{
            click: function(){
              parent.$('recordMessagesPanel').childElements().each(function(e){e.hide();}); 
              source = $('current-displayed-iframe-source').value;
              if( source == "/admin/parties")
                recordMessagesRefresh($('contact-list-ids').value);
              else if(source && source.match(/parties\/\d+/)){
                if(el=$("party_".concat(source.match(/\d+(?!parties\/)/), "_messages")))
                  el.remove();
                recordMessagesRefresh($('current-displayed-iframe-source').value.match(/\d+(?!parties\/)/));
              }
            }
          }
        }]
      },
      {
        id: 'eastPanel-filesPanel',
        title: "<span id='record-files-title'>Files</span>",
        collapsible: true,
        animCollapse: true,
        contentEl: "recordFilesPanel",
        tools: [{
          id:'refresh',
          on:{
            click: function(){
              parent.$('recordFilesPanel').childElements().each(function(e){e.hide();}); 
              source = $('current-displayed-iframe-source').value;
              if( source == "/admin/parties")
                recordFilesRefresh($('contact-list-ids').value);
              else if(source && source.match(/parties\/\d+/)){
                if(el=$("party_".concat(source.match(/\d+(?!parties\/)/), "_files")))
                  el.remove();
                recordFilesRefresh($('current-displayed-iframe-source').value.match(/\d+(?!parties\/)/));
              }
            }
          }
        }]
      },
      {
        id: 'eastPanel-paymentsPanel',
        title: "<span id='record-payments-title'>Payments</span>",
        collapsible: true,
        animCollapse: true,
        contentEl: "recordPaymentsPanel",
        tools: [{
          id:'refresh',
          on:{
            click: function(){
              parent.$('recordPaymentsPanel').childElements().each(function(e){e.hide();}); 
              source = $('current-displayed-iframe-source').value;
              if( source == "/admin/parties")
                recordPaymentsRefresh($('contact-list-ids').value);
              else if(source && source.match(/parties\/\d+/)){
                if(el=$("party_".concat(source.match(/\d+(?!parties\/)/), "_payments")))
                  el.remove();
                recordPaymentsRefresh($('current-displayed-iframe-source').value.match(/\d+(?!parties\/)/));
              }
            }
          }
        }]
      }
    ]
  });

  xl.backgroundPanel = new Ext.Panel({
    html: "",
    autoScroll: true
  });
  xl.backgroundPanel.hide();
  xl.backgroundPanel.on("beforeshow", function(thisPanel){xl.tabPanel.hide()});
  xl.backgroundPanel.on("hide", function(thisPanel){xl.tabPanel.show()});

  // We need to keep this center panel around for adding tabs later
  xl.tabPanel = new Ext.TabPanel({
    defaults: { autoScroll: false, closable: true },
    border: false,
    frame: false,
    deferredRender: false,
    enableTabScroll: true
  });
  
  xl.tabPanel.on("beforeadd", function(){ xl.backgroundPanel.hide()});
  
  xl.centerPanel = new Ext.Panel({
    frame: false,
    border: false,
    autoScroll: true,
    cls:"centerPanel",
    region: 'center',
    bbar: xl.setup.generateFooterToolbar(),
    tbar: ['<span id="status-bar-notifications"></span>'],
    items: [ {items: [xl.backgroundPanel], autoScroll: true}, xl.tabPanel ]
  });

  xl.viewport = new Ext.Viewport({
    renderTo: Ext.getBody(),

    layout: 'border',
    cls: "mainPanel",
    items: [
      {
        region: 'north',
        height: 24
      },
      xl.westPanel,
      xl.centerPanel,
      xl.eastPanel
    ]
  });

  // Force a render to prevent anything from
  // being cut off
  xl.viewport.render();
    
  Ext.Ajax.request({
    url: "/admin/landing_page",
    method: "GET"
  });

  updateNotificationBar();

  //show unread emails in Unread Messages panel in the west console
  unreadMailRefresh();
  //show sent and read emails in My History panel in the west console
  sentReadMailRefresh();
  //show feeds in My Feeds panel in the west
  myFeedsShow();
  myEmailLabelsRefresh();

  // Expand the panels that need to be expanded.
  // This must be done *after* the viewport is rendered!
  xl.panelsToExpand.forEach(function(panel, i, array) {
    panel.expand(true);
  });

  //*** Events ***//
  // bodyresize actually happens before resize,
  // so the sooner the better
  xl.centerPanel.on('resize', xl.resizeTabPanel);

  // When the window is closed, save some information
  Ext.EventManager.addListener(window, 'unload', function() {
    // Maybe we should force logout here for safety!
  // Save the activeItems of the accordions for next time
  Ext.state.Manager.set('westPanel.activeItem.id', xl.westPanel.getLayout().activeItem.getId());
  Ext.state.Manager.set('eastPanel.activeItem.id', xl.eastPanel.getLayout().activeItem.getId());
  });
});
