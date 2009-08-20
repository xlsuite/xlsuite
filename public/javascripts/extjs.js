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
    title: "<div class='left-console-title'>My Dashboard</div>",
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
        id:'westPanel-quickEntryPanel',
        title: 'Quick Entry',
        contentEl: 'quickEntryPanel'
      },/**{
        id:'westPanel-mailPanel',
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
      },**/
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
      }/**,{
        id: 'westPanel-savedSearchesPanel',
        title: 'My Saved Searches',
        contentEl: 'mySavedSearchesPanel'
      }**/
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
    defaults: { autoScroll: false, closable: true }
    ,border: false
    ,frame: false
    ,enableTabScroll: true
    ,plugins:new Ext.ux.TabCloseMenu()
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
    items: [ xl.backgroundPanel, xl.tabPanel ]
  });
  
  xl.viewport = new Ext.Viewport({
    renderTo:Ext.getBody()
    ,layout:'border'
    ,cls:"mainPanel"
    ,items: [
      {
        region:'north'
        ,height:30
        ,cls:"northPanel"
      }
      ,xl.westPanel
      ,xl.centerPanel
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
  });
});
