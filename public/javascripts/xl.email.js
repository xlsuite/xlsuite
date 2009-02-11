Ext.namespace('xl.email');  
xl.email = function() {}

xl.email.pageSize = 10;

xl.email.defaultMailPanelMessage = '<p>Double-click an email to display it.</p>';

// This record illustrates all the data a GridPanel can show
// The ColaumnModel determines what is shown
xl.email.truncatedRecord = Ext.data.Record.create([
  {name: 'id'},
  {name: 'subject'},
  {name: 'received_at'},
  {name: 'updated_at'},
  {name: 'released_at'},
  {name: 'created_at'},
  {name: 'scheduled_at'},
  {name: 'sender_id'},
  {name: 'sender_name'},
  {name: 'sender_address'},
  {name: 'party_id'},
  {name: 'to_names'},
  {name: 'sent_at'}, 
  {name: 'body'}
]);

xl.email.messageTemplate = new Ext.Template(
  '<table class="emailFieldsTable">',
    '<tr><td class="emailFieldLabel">From:</td><td>{from_name} &lt;{from_address}&gt;</td></tr>',
    '<tr><td class="emailFieldLabel">Subject:</td><td>{subject}</td></tr>',
    '<tr><td class="emailFieldLabel">Date:</td><td>{date}</td></tr>',
    //'<tr><td class="emailFieldLabel">To:</td><td>{to}</td></tr>',
    //'<tr><td class="emailFieldLabel">Cc:</td><td>{cc}</td></tr>',
    //'<tr><td class="emailFieldLabel">Actions:</td><td><a href="/admin/emails/{id};destroy">Delete</a></td></tr>',
    '<tr><td colspan="2" class="emailBody">{body}</td></tr>',
  '</table>'
);

xl.email.alertNoEmailSelected = function() {
  Ext.Msg.alert('No Emails Selected', 'Please select one or more emails to perform that action.');
}

xl.email.generateActionMenu = function(gridPanel, actionMenuId) {
  var shouldBeDisabled = false;
  if (gridPanel == null) shouldBeDisabled = true;
  
  var actionMenu = new Ext.menu.Menu({
    defaults: { iconCls: 'display_none' },
    items: [
      {
        text: "Select all",
        handler: function(e) { gridPanel.getSelectionModel().selectAll(); },
        disabled: shouldBeDisabled
      },{
        text: "Clear all",
        handler: function(e) { gridPanel.getSelectionModel().clearSelections(); },
        disabled: shouldBeDisabled
      },'-',{
        text: "Add Contacts to Group",
        handler: function() {
          // Get all the records and ids for the selected emails
          var records = gridPanel.getSelectionModel().getSelections();
          if (records.length == 0) {
            xl.email.alertNoEmailSelected();
            return false;
          }
          
          var ids = records.invoke('get', 'party_id');
          
          var connection = new Ext.data.Connection({url: '/admin/groups/async_get_name_id_hashes', method: 'get'});
          var reader = new Ext.data.JsonReader(
            {totalProperty: "total", root: "collection", id: "id"},
            new Ext.data.Record.create([
              {name: 'name'}, {name: 'id'}
            ])
          );
          var store = new Ext.data.Store({
            proxy: new Ext.data.HttpProxy(connection),
            reader: reader
          });
          store.load();
          
          var comboBoxId = Ext.id();
          // request.responseText is an Array of Hashes containing
          // the name and id of the group. These will populate the
          // ComboBox
          // It will all be shown in win
          var win = new Ext.Window({
            width: 300,
            height: 100,
            layout: 'fit',
            plain: true,
            title: 'Add Parties to Group',
            modal: true,
            // win has just one Panel
            items: [new Ext.form.FormPanel({
              width: 190,
              labelPad: 10,
              labelWidth: 100,
              labelAlign: 'top',
              items: [
                new Ext.form.ComboBox({
                  store: store,
                  displayField: 'name',
                  typeAhead: false,
                  mode: 'remote',
                  triggerAction: 'all',
                  selectOnFocus:true,
                  allowBlank: false,
                  autoWidth: true,
                  fieldLabel: 'Choose a Group into which to add the selected parties, or type a name to create a new Group with default permissions<br />',
                  id: comboBoxId
                })] // end Ext.Panel.items[]
              }) // end Ext.Panel
            ],  // end Ext.Window.items[]
            buttons: [{
              text: 'Add',
              handler: function() {
                var comboBox = Ext.getCmp(comboBoxId);
                Ext.Ajax.request({
                  url: '/admin/groups/async_add_parties_or_create',
                  method: 'POST',
                  params: { name: comboBox.getRawValue(), ids: ids.join(',') },
                  failure: function(request, options) {
                    win.close();
                    xl.log("FAILURE: " + request);
                  }, success: function(request, options) {
                    win.close();
                    xl.log("SUCCESS: " + request);
                    //xl.createTab(request.responseText);
                  }
                });
              }
            },{
              text: 'Cancel',
              handler: function() { win.close(); }
            }]  // end Ext.Window.buttons[]
          }); // end Ext.Window
          
          win.show();
        } // end handler()
      },{
        text: "Email Parties",
        handler: function() {
          var records = gridPanel.getSelectionModel().getSelections();
          if (records.length == 0) {
            xl.email.alertNoEmailSelected();
            return false; // Cancel the Email Parties Action
          }
          
          var numBlankEmails = 0;
          var to_name_addresses = records.collect(function(record) {
            // Make sure the address is there and not blank
            if (record.get('sender_address') && record.get('sender_address') != '')
              // Someone <someone@domain.com>
              return record.get('sender_name') + ' <' + record.get('sender_address') + '>';
            else
              numBlankEmails++;
          });
          
          if (numBlankEmails == to_name_addresses.length) {
            Ext.MessageBox.alert('No Email Addresses', 'The selected contacts do not have email addresses.');
            return false; // Cancel the Email Parties Action
          }
          
          xl.createTabAsDiv('/admin/emails/sandbox_new?to_name_addresses=' + to_name_addresses.uniq().join(', '));
        }
      },{
        text: "Mass Mail Parties"
      },{
        text: "Print",
        disabled: true
      },{
        text: "Send a File",
        disabled: true
      },{
        text: "Send a Link",
        disabled: true
      },{
        text: "Tag Contacts",
        handler: function() { 
          Ext.Msg.prompt("Tag Selected Contacts", "Please enter a Tag", function(btn, text) {
            if ( btn.match(new RegExp("ok","i")) ) { 
              Ext.Ajax.request({
                url: '/admin/parties/async_tag_parties',
                method: 'POST',
                params: { tag_list: text, ids: ids.join(',') },
                failure: xl.logXHRFailure
              }); // Ext.Ajax.request
            } // end if
          }); // Ext.Msg.prompt
        }
      },'-',{
        text: "Archive"
      },{
        text: "Delete",
        handler: function() { 
          var records = gridPanel.getSelectionModel().getSelections();
          if (records.length == 0) {
            xl.email.alertNoEmailSelected();
            return false;
          }
          
          var ids = records.invoke('get', 'id');  // Returns an Array of the ids retrieved by calling .get('id') on each record in records
          
          Ext.Msg.confirm("Confirm Delete", "Are you sure you want to delete the selected email(s)?", function(buttonText) {
            if (buttonText.match(new RegExp("yes","i"))) {
              Ext.Ajax.request({
                url: "/admin/emails/async_destroy_collection",
                method: "POST",
                params: { ids: ids.join(', ') },
                failure: xl.logXHRFailure,
                success: function(request, options) {
                  xl.log("SUCCESS: " + request.responseText);
                  gridPanel.getStore().reload();
                } // end success(r,o)
              }); // end Ext.Ajax.request
            } // end if(buttonText.match...
          }); // end Ext.Msg.confirm
        }   // end handler
      } // end button
    ]
  });
  
  return { id: actionMenuId, text: "Actions", menu: actionMenu }
}

xl.email.asyncLoadMessage = function(id, messagePanelId) {
  var wrapper = Ext.getCmp(messagePanelId + '.wrapper');
  
  /*if (wrapper.xlEmail_hasBeenUsed) {
    // open in new tab: /admin/emails/sandbox?mailbox=inbox&id=165
    xl.createTabAsDiv('/admin/emails/sandbox?id=' + id);
    return;
  }*/
  
  // Request the HTML
  Ext.Ajax.request({
    url: "/admin/emails/async_get_email",
    method: 'get',
    params: {id: id},
    failure: xl.logXHRFailure,
    success: function(request, options) {
      xl.log ('Created newPanel. Destroying previous panel...');
      
      wrapper.remove(messagePanelId, true);
      
      xl.log('Previous panel destroyed! Adding newPanel...');
      
      try {
      // This panel is the replacement panel
      var newPanel = new Ext.Panel({
        region: 'center',
        height: 400,
        autoScroll: true,
        cls: 'emailMessage',  // This applies to the class of the base Element
        id: messagePanelId,
        html: request.responseText,
        // Using an id instead of a contentEl means we don't have to clean
        // the contentEl up after the panel is destroyed; we just have to
        // keep track of this ID
        tbar: new Ext.Toolbar({
          items: [
            xl.email.generateActionMenu(null, messagePanelId + '.actionMenu'),
            {
              text: "Reply",
              handler: function() { xl.createTab('/admin/emails/' + id + '/reply/'); }
            },{
              text: "Reply To All",
              handler: function() { xl.createTab('/admin/emails/' + id + '/reply_all/'); }
            },{
              text: "Forward",
              handler: function() { xl.createTab('/admin/emails/' + id + '/forward/'); }
            }
          ]
        })
      }); // end new Ext.Panel
      } catch (error) {
        xl.log(error);
      }
      
      newPanel.getTopToolbar().addClass("headerBar");
      
      // Some of these lines aren't needed...
      wrapper.add(newPanel);
      wrapper.render();
      wrapper.doLayout();
      wrapper.syncSize();
      wrapper.xlEmail_hasBeenUsed = true;
      xl.log('newPanel added and wrapper marked as used!');
      Ext.Ajax.request({
        url: "/admin/emails/update_west_console",
        method: 'get',
        failure: xl.logXHRFailure
      });
      
    } // end success()
  }); // end Ext.Ajax.request  
} // end xl.asyncLoadMessage

xl.email.generateMailboxPanel = function(mailboxName, columnModelArray, messagePanelId, idToLoad) {
  try {
  
  var gridPanelContainerId = 'xl.email.gridPanel.container.' + mailboxName;  
  var gridPanelId = 'xl.email.gridPanel.' + mailboxName;
  var storeId = 'xl.email.store.' + mailboxName;
  
  xl.log('xl.email.generateMailboxPanel Top. Creating connection and reader...');
  
  var connection = new Ext.data.Connection({url: '/admin/emails/async_get_mailbox_emails', method: 'get'});
  var reader = new Ext.data.JsonReader({totalProperty: "total", root: "collection", id: "id"}, xl.email.truncatedRecord);
  
  xl.log('Created connection and reader! Creating and loading store...');
  
  var store = Ext.StoreMgr.lookup(storeId);
  if (!store) {
    xl.log(storeId + ' does not yet exist. Creating it...');
    store = new Ext.data.Store({
      proxy: new Ext.data.HttpProxy(connection),
      reader: reader,
      remoteSort: true,
      baseParams: {q:'', mailbox: mailboxName},
      id: storeId
    });
  } else {
    xl.log(storeId + ' is already lurking about. Using it!');
  }
  
  xl.log("Created and loaded store! Creating paginator...");
  
  // define paging toolbar that is going to be appended to the footer of the grid panel
  var paginator = new Ext.PagingToolbar({
    store: store,
    pageSize: xl.email.pageSize,
    displayInfo: true,
    displayMsg: 'Displaying {0} to {1} of {2}',
    emptyMsg: "No emails to display",
    cls: "paging-toolbar-bottom",
    plugins: [new Ext.ux.PageSizePlugin]
  });
  
  xl.log("Created paginator! Creating filter...");

  //create filter field to be appended as the top grid toolbar
  var filterField = new Ext.form.TextField({selectOnFocus: true, grow: false, emptyText: "Search"})
  filterField.on("specialkey",
    function(field, e) {
      if (e.getKey() == Ext.EventObject.RETURN || e.getKey() == Ext.EventObject.ENTER) {
        e.preventDefault();
        xl.log('Filtering ' + gridPanelId + ' by "' + this.getValue() + '"');
        store.baseParams['q'] = this.getValue();
        store.reload({params: {start: 0, limit: xl.email.pageSize}});
      }
    }
  );    

  // clear button for the filter field
  var clearButton = new Ext.Toolbar.Button({
    text: 'Clear', 
    handler: function() {
      filterField.setValue("");
      store.baseParams['q'] = "";
      store.reload();
    }
  });
  
  xl.log ("Created filter! Creating grid panel...");
  
  var gridPanel = new Ext.grid.GridPanel({
    store: store,
    cm: new Ext.grid.ColumnModel(columnModelArray),
    
    viewConfig: { forceFit: true },
    cls: 'border2pxLightGreen',
    autoHeight: false,
    height: 200,
    width: '90%',
    autoExpandColumn: 'subject',
    header: false,
    footer: true,
    tbar: new Ext.Toolbar({
      cls: 'bg-brown',
      items: ["Filter: ", filterField, clearButton]
    }),
    bbar: [paginator],
    title: mailboxName.capitalize(),
    renderTo: gridPanelContainerId,
    
    id: gridPanelId
  });
  
  gridPanel.emailGridHeight = 200;
  
  gridPanel.getTopToolbar().add(xl.email.generateActionMenu(gridPanel, gridPanelId + '.actionMenu'));
   store.load({params: {start: 0, limit: xl.email.pageSize}});
  gridPanel.getTopToolbar().addClass("top-toolbar");
  gridPanel.getBottomToolbar().addClass("bottom-toolbar");
  xl.runningGrids.set("emails", gridPanel);
  
  xl.log('Created grid panel! Adding onrowdblclick event...');
  
  //On row double-click...
  gridPanel.on('celldblclick', function(grid, rowIndex, colIndex, e) {
    xl.log('Cell at (' + colIndex + ',' + rowIndex + ') double-clicked...');
    
    var record = this.getStore().getAt(rowIndex);
    if (mailboxName == "draft") {
      xl.openNewTabPanel('emails_edit_' + record.get('id'), 'admin/emails/' + record.get('id') + '/edit');
    }
    else {
      // Check the column clicked...
      if (colIndex == 0) {
        // The first column will always refer to a party
        // to which we can navigate
        xl.log('Party id #' + record.get('party_id') + ' requested');
        xl.createTab('/admin/parties/' + record.get('party_id') + '/general');
      }
      else {
        xl.email.asyncLoadMessage(record.get('id'), messagePanelId);
      } // else
    }
  });  // gridPanel.on celldblclick
  
  xl.log("Added onrowdblclick! End of xl.email.generateMailboxPanel...");

  return gridPanel;
  
  } catch(error) {
    xl.log("Error in xl.email.generateMailboxPanel: ");
    xl.log(error);
  }
}

xl.email.senderNameRenderer = function(value, metadata, record, row, col, store) {
  if (value == null || value == '')
    return record.get('sender_address');
  else
    return value;
}

/*
 * Render the date in an appropriate format:
 * Today at 6:01 PM
 * Yesterday at 6:01 PM
 * October 28, 2007 at  6:01 PM
 */
xl.email.dateRenderer = function(value, metadata, record, row, col, store) {
  var timeFormat = ' \\a\\t h:i A';
  var previousFormat = 'F j, Y' + timeFormat;
  
  var date = new Date(value);
  var today = new Date();
  if (date.format('Y-m-d')==today.format('Y-m-d')) { 
    return "Today"+ date.format(timeFormat);
  } else{
    return date.format(previousFormat);
  }
}

xl.email.refreshMailboxes = function(){
  ['inbox', 'outbox', 'draft', 'sent'].each(function(n){
    var s = Ext.StoreMgr.lookup('xl.email.store.'+n)
    if (s) {
      s.reload();
    }
  });
}
