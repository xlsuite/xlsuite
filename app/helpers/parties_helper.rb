#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module PartiesHelper
  def initialize_imap_account_panel
    %Q`
      var imapSetupUsername = new Ext.form.TextField({
        fieldLabel:"Username"
        ,grow:true
        ,growMin:200
        ,value:#{@imap_account.username.to_json}
      });
      
      var realImapServerField = new Ext.form.Hidden({
        value:#{@imap_account.default_server.to_json}
      });
      
      var fakeImapServerField = new Ext.form.TextField({
        fieldLabel:"Server"
        ,value:#{@imap_account.server.to_json}
        ,listeners:{
          "keyup":function(cpt, event){
            realImapServerField.setValue(cpt.getValue());
          }
        }
      });

      var realImapPortField = new Ext.form.Hidden({
        value:#{@imap_account.default_port.to_json}
      });
      
      var fakeImapPortField = new Ext.form.TextField({
        fieldLabel:"Port"
        ,value:#{@imap_account.port.to_json}
        ,listeners:{
          "keyup":function(cpt, event){
            realImapPortField.setValue(cpt.getValue());
          }
        }
      });
      
      var fakeImapServerPortWrapper = new Ext.Panel({
        layout:"form"
        ,hidden:true
        ,items:[fakeImapServerField,fakeImapPortField]
      });
      
      var imapTypeSelection = new Ext.form.ComboBox({
        store:#{ImapEmailAccount::DEFAULT_SELECTIONS.to_json}
        ,forceSelection:true
        ,editable:false
        ,mode:"local"
        ,triggerAction:"all"
        ,fieldLabel:"Provider"
        ,value:#{@imap_account.default_server_name.to_json}
        ,listeners:{
          "select":function(cpt, record, index){
            switch(record.get("text")){
              case "Other":
                fakeImapServerPortWrapper.show();
                break;
              case "Google Mail":
                fakeImapServerPortWrapper.hide();
                realImapServerField.setValue("imap.google.com");
                realImapPortField.setValue("993");
                break;
            }
          }
        }
      });
      
      var imapSetupPassword = new Ext.form.TextField({
        fieldLabel:"Password"
        ,grow:true
        ,growMin:200
        ,inputType:"password"
        ,value:#{@imap_account.password.to_json}
      });
      
      var imapEmailAccountId = #{@imap_account.id.to_json};
      
      var imapTestFunction = function(btn){
        var url = #{test_party_email_account_path(:party_id => @party.id, :id => "__ID__").to_json};
        Ext.Ajax.request({
          url:url.replace("__ID__", imapEmailAccountId)
          ,method:"GET"
          ,success:function(response,options){
            var response = Ext.decode(response.responseText);
            if(response.success){
              Ext.Msg.alert("IMAP Account Setup", "Proper connection established with your email account")
            }
            else{
              Ext.Msg.alert("IMAP Account Setup - FAILED", response.error)
            }
          }
        });
      }
      
      var imapSaveButton = new Ext.Toolbar.Button({
        text:"Save"
        ,handler:function(btn){
          var params = {"type":"imap"};
          var method = "POST";
          var url = #{party_email_accounts_path(:party_id => @party.id).to_json};
          params["email_account[server]"] = realImapServerField.getValue();
          params["email_account[port]"] = realImapPortField.getValue();
          params["email_account[username]"] = imapSetupUsername.getValue();
          params["email_account[password]"] = imapSetupPassword.getValue();
          if(imapEmailAccountId){
            params["id"] = imapEmailAccountId;
            method = "PUT"
            url = #{party_email_account_path(:party_id => @party.id, :id => "__ID__").to_json};
            url = url.replace("__ID__", imapEmailAccountId);
          }
          Ext.Ajax.request({
            url:url
            ,params:params
            ,method:method
            ,success:function(response,options){
              var response = Ext.decode(response.responseText);
              if(response.success){
                imapEmailAccountId = response.id;
                Ext.Msg.alert("IMAP Account Setup"
                  ,"Your IMAP setting has been saved. Your IMAP setting will be validated shortly."
                  ,imapTestFunction
                );
              }
              else{
                Ext.Msg.alert("IMAP Account Setup - FAILED", response.errors.join("<br/>"));
              }
            }
          });
        }
      });
      
      var shareMyImapButton = new Ext.Toolbar.Button({
        text:"Share IMAP"
        ,tooltip:"Clicking this button will enable you to share your contact IMAP with this contact"
        ,disabled:#{@disable_share_imap.to_json}
        ,handler:function(btn){
          Ext.Ajax.request({
            url:#{shared_email_accounts_path(:email_account_id => @current_user_imap_account.id).to_json}
            ,method:"POST"
            ,params:{"target_type":"Party","target_id":#{@party.id.to_json}}
            ,success:function(response,options){
              var response = Ext.decode(response.responseText);
              if(response.success){
                Ext.Msg.alert("IMAP Sharing", "Your IMAP has been successfully shared with this contact");
              }
              else{
                Ext.Msg.alert("IMAP Sharing", response.errors.join("<br/>"));
              }
            }
          })
        }
      });
      
      var imapTestButton = new Ext.Toolbar.Button({
        text:"Test"
        ,disabled:#{(!@party.own_imap_account?).to_json}
        ,handler:function(btn){imapTestFunction(btn)}
      });
      
      var imapSetupPanel = new Ext.Panel({
        layout:"form"
        ,items:[imapTypeSelection,fakeImapServerPortWrapper,imapSetupUsername,imapSetupPassword]
        ,tbar:[imapSaveButton, imapTestButton, shareMyImapButton]
      });
      
      var emailAccountRolesRootTreeNode =  new Ext.tree.AsyncTreeNode({
        text:"Role - Root"
        ,expanded:true
        ,id:0
      });

      var emailAccountRolesFileTreePanel = new Ext.tree.TreePanel({
        title:"Sharing with Roles"
        ,columnWidth:.5
        ,root:emailAccountRolesRootTreeNode
        ,rootVisible: false
        ,disabled:#{!@party.own_imap_account?.to_json}
        ,autoScroll:true
        ,loader:new Ext.tree.TreeLoader({
          requestMethod: "GET"
          ,url: #{formatted_roles_tree_shared_email_accounts_path(:email_account_id => @imap_account.id, :format => :json).to_json}
          ,baseAttrs: {uiProvider: Ext.tree.TreeCheckNodeUI}
        })
        ,listeners:{
          check: function(node, checked){
            var url = null;
            var method = null;
            if(checked){
              url = #{shared_email_accounts_path.to_json};
              method = "POST";
            }
            else{
              url = #{remove_shared_email_accounts_path.to_json};
              method = "DELETE";
            }
            Ext.Ajax.request({
              url:url
              ,method:method
              ,params:{target_type:"Role",target_id:node.id,email_account_id:imapEmailAccountId}
            });
          }
          ,render:function(cpt){
            cpt.setHeight(cpt.ownerCt.ownerCt.getSize().height-imapSetupPanel.getSize().height);
          }
        }
      });

      var SharedPartyRecord = new Ext.data.Record.create([
        {name:"id"}
        ,{name:"display_name"}
      ]);

      var sharedPartyReader = new Ext.data.JsonReader({totalProperty: "total", root: "collection", id: "id"}, SharedPartyRecord);
      var sharedPartyConnection = new Ext.data.Connection({url: #{parties_shared_email_accounts_path(:email_account_id => @imap_account.id).to_json}, method: 'get'});
      var sharedPartyProxy = new Ext.data.HttpProxy(sharedPartyConnection);

      var sharedPartyStore = new Ext.data.Store({
        proxy:sharedPartyProxy 
        ,reader:sharedPartyReader 
        ,remoteSort:false
        ,autoLoad:true
      });
      
      var removeSharedPartyButton = new Ext.Toolbar.Button({
        text:"Remove"
        ,disabled:true
        ,handler:function(btn){
          Ext.Ajax.request({
            url:#{remove_collection_shared_email_accounts_path.to_json}
            ,params:{"target_type":"Party","target_ids":selectedSharedPartyIds.join(","),"email_account_id":#{@imap_account.id.to_json}}
            ,method:"DELETE"
            ,success:function(response, options){
              var response = Ext.decode(response.responseText)
              if(response.success){
                sharedPartyStore.reload();
              }
            }
          })
        }
      });
      
      var emailAccountPartiesTopToolbar = new Ext.Toolbar({
        items:[removeSharedPartyButton]
      });

      var selectedSharedPartyIds = null;

      var emailAccountPartiesSelectionModel = new Ext.grid.RowSelectionModel({
        listeners:{
          selectionchange:function(sm){
            var records = sm.getSelections();
            selectedSharedPartyIds = [];
            for(var i=0;i<records.length;i++){
              selectedSharedPartyIds.push(records[i].get("id"));
            }
            if(selectedSharedPartyIds.length>0){
              removeSharedPartyButton.enable();
            }
            else{
              removeSharedPartyButton.disable();
            }
          }
        }
      });
      
      var emailAccountPartiesGridPanel = new Ext.grid.GridPanel({
        title:"Sharing with contacts"
        ,columnWidth:.5
        ,store:sharedPartyStore
        ,cm:new Ext.grid.ColumnModel([
          {id:"name",header:"Name",dataIndex:"display_name"}
        ])
        ,sm:emailAccountPartiesSelectionModel
        ,bbar:emailAccountPartiesTopToolbar
        ,autoExpandColumn:"name"
        ,emptyText:"Not sharing with any contact"
        ,listeners:{
          render:function(cpt){
            cpt.setHeight(cpt.ownerCt.ownerCt.getSize().height-imapSetupPanel.getSize().height);
          }
        }
      });
      
      var imapAccountPanel = new Ext.Panel({
        title:"IMAP Setup"
        ,items:[
          imapSetupPanel, 
          {layout:"column", items:[emailAccountRolesFileTreePanel, emailAccountPartiesGridPanel]}
        ]
      });
    `
  end

  def initialize_testimonials_panel
    limit = params[:limit] || 50
    testimonials_url_json = formatted_testimonials_path(:author_id => @party.id, :format => :json).to_json
    %Q`
      var testimonialSelectedIds = null;
      var editTestimonialUrl = #{edit_testimonial_path("__ID__").to_json};

      // create file record
      var TestimonialRecord = new Ext.data.Record.create([
        {name: 'id', mapping: 'id'},
        {name: 'object_id', mapping: 'object_id'},
        {name: 'author_name', mapping: 'author_name'},
        {name: 'author_company_name', mapping: 'author_company_name'},
        {name: 'email_address', mapping: 'email_address'},
        {name: 'website_url', mapping: 'website_url'},
        {name: 'phone_number', mapping: 'phone_number'},
        {name: 'body', mapping: 'body'},
        {name: 'status', mapping: 'status'}
      ]);

      // data reader to parse the json response
      var partyTestimonialsReader = new Ext.data.JsonReader({totalProperty: "total", root: "collection", id: "id"}, TestimonialRecord);

      // set up connection of the data
      var partyTestimonialsConnection = new Ext.data.Connection({url: #{testimonials_url_json}, method: 'get'});
      var partyTestimonialsProxy = new Ext.data.HttpProxy(partyTestimonialsConnection);

      // set up the data store and then send request to the server
      var partyTestimonialsDs = new Ext.data.Store({proxy: partyTestimonialsProxy, reader: partyTestimonialsReader, remoteSort: true, baseParams: {q: ''}});

      // define paging toolbar that is going to be appended to the footer of the grid panel
      var partyTestimonialsPaging = new Ext.PagingToolbar({
        store: partyTestimonialsDs,
        pageSize: #{limit},
        displayInfo: true,
        displayMsg: 'Displaying {0} to {1} of {2}',
        emptyMsg: "No record to display",
        cls: "bottom-toolbar paging-toolbar-bottom",
        plugins: [new Ext.ux.PageSizePlugin]
      });

      #{create_grid_tbar_filter_field("partyTestimonialsDs")}

      #{create_grid_tbar_clear_button("partyTestimonialsDs")}
      
      var newTestimonialButton = new Ext.Toolbar.Button({
        text: 'New',
        handler: function() {
          xl.openNewTabPanel('testimonials_new_nil', #{new_testimonial_path.to_json});
        }
      });

      var testimonialSelectAllAction = new Ext.Action({
        text: "Select all",
        iconCls: "display_none"
      });

      var testimonialClearAllAction = new Ext.Action({
        text: "Clear all",
        iconCls: "display_none",
        disabled: true
      });
      
      var testimonialApproveAction = new Ext.Action({
        text: "Approve",
        iconCls: "display_none",
        disabled: true
      });
      
      var testimonialRejectAction = new Ext.Action({
        text: "Reject",
        iconCls: "display_none",
        disabled: true
      });
      
      var testimonialDeleteAction = new Ext.Action({
        text: "Delete",
        iconCls: "display_none",
        disabled: true
      });
      
      var testimonialSelectionMenu =  new Ext.menu.Menu({
        items: [testimonialSelectAllAction, testimonialClearAllAction]
      });
      
      testimonialSelectionMenu.addSeparator();
      testimonialSelectionMenu.add(testimonialApproveAction);
      testimonialSelectionMenu.add(testimonialRejectAction);
      testimonialSelectionMenu.addSeparator();
      testimonialSelectionMenu.add(testimonialDeleteAction);
      
      var partyTestimonialsGridTopToolbar = new Ext.Toolbar({
        cls: "top-toolbar",
        items: [
          {text:"&nbsp;&nbsp;&nbsp;Filter: "}, filterField, clearButton, 
          {text: "Actions", menu: testimonialSelectionMenu},
          newTestimonialButton
        ]
      });

      var partyTestimonialsGrid = new Ext.grid.GridPanel({
        store: partyTestimonialsDs,
        cm: new Ext.grid.ColumnModel([
            {id: "testimonial-email_address", header: "Email", sortable: true, hidden: true, dataIndex: 'email_address'},
            {id: "testimonial-website_url", header: "Website", sortable: true, hidden: true, dataIndex: 'website_url'},
            {id: "testimonial-phone_number", header: "Phone", sortable: true, hidden: true, dataIndex: 'phone_number'},
            {id: "testimonial-body", header: "Body", sortable: false, dataIndex: 'body'},
            {id: "testimonial-status", header: "Status", width: 100, sortable: false, dataIndex: 'status'}
          ]),
        autoScroll: true,
        autoWidth: true,
        height: 200,
        tbar: partyTestimonialsGridTopToolbar,
        bbar: partyTestimonialsPaging,
        selModel: new Ext.grid.RowSelectionModel,
        loadMask: true,
        viewConfig: { autoFill: true, forceFit: true},
        listeners: {
          render: function(cpt){
            partyTestimonialsDs.load({params: {start: 0, limit: #{limit} }});
          },
          resize: function(component){
            var size = component.ownerCt.ownerCt.body.getSize();
            component.suspendEvents();
            component.setSize(size.width, size.height);
            component.resumeEvents();
          },
          rowdblclick: function(cpt, rowIndex, event){
            var record = partyTestimonialsDs.getAt(rowIndex);
            var id = record.data.id;
            xl.openNewTabPanel('testimonials_edit_'+id, editTestimonialUrl.sub("__ID__", id));
          }
        }
      });

      testimonialClearAllAction.setHandler(function(e) {
        partyTestimonialsGrid.getSelectionModel().clearSelections();
        e.disable();
      });

      testimonialSelectAllAction.setHandler(function(e) {
        partyTestimonialsGrid.getSelectionModel().selectAll();
        e.disable();
      });

      testimonialApproveAction.setHandler(function(e) {
        Ext.Msg.confirm("", "Approve selected testimonials?", function(btn){
          if ( btn.match(new RegExp("yes","i")) ) {
            var params = {};
            partyTestimonialsGrid.disable();
            params['ids'] = testimonialSelectedIds.join(",");
            new Ajax.Request(#{approve_collection_testimonials_path.to_json}, {
              method: 'put',
              parameters: params,
              onSuccess: function(transport){
                partyTestimonialsDs.reload();
                partyTestimonialsGrid.enable();
              }
            });
          }
        });
      });

      testimonialRejectAction.setHandler(function(e) {
        Ext.Msg.confirm("", "Reject selected testimonials?", function(btn){
          if ( btn.match(new RegExp("yes","i")) ) {
            var params = {};
            partyTestimonialsGrid.disable();
            params['ids'] = testimonialSelectedIds.join(",");
            new Ajax.Request(#{reject_collection_testimonials_path.to_json}, {
              method: 'put',
              parameters: params,
              onSuccess: function(transport){
                partyTestimonialsDs.reload();
                partyTestimonialsGrid.enable();
              }
            });
          }
        });
      });

      testimonialDeleteAction.setHandler(function(e) {
        Ext.Msg.confirm("", "Delete selected testimonials permanently?", function(btn){
          if ( btn.match(new RegExp("yes","i")) ) {
            var params = {};
            partyTestimonialsGrid.disable();
            params['ids'] = testimonialSelectedIds.join(",");
            new Ajax.Request(#{destroy_collection_testimonials_path.to_json}, {
              method: 'delete',
              parameters: params,
              onSuccess: function(transport){
                partyTestimonialsDs.reload();
                partyTestimonialsGrid.enable();
              }
            });
          }
        });
      });

      partyTestimonialsGrid.getSelectionModel().on("selectionchange", function(){
        records = partyTestimonialsGrid.getSelectionModel().getSelections();
        var ids = new Array();
        records.each( function(e) {
          ids.push(e.data.id);
        });
        testimonialSelectedIds = ids;
        
        if(ids.length>0){
          testimonialClearAllAction.enable();
          testimonialDeleteAction.enable();
          testimonialApproveAction.enable();
          testimonialRejectAction.enable();
        }
        else {
          testimonialApproveAction.disable();
          testimonialRejectAction.disable();
          testimonialDeleteAction.disable();
          testimonialSelectAllAction.enable();
        }
      });

      var testimonialsPanel = new Ext.Panel({
        items: [partyTestimonialsGrid]
      })
    `
  end

  def initialize_notes_panel
    limit = params[:limit] || 50
    %Q`
      var selectedNoteIds = null;

      var NoteRecord = new Ext.data.Record.create([
          {name: 'id', mapping: 'id'},
          {name: 'created_at', mapping: 'created_at'},
          {name: 'updated_at', mapping: 'updated_at'},
          {name: 'created_by_name', mapping: 'created_by_name'},
          {name: 'updated_by_name', mapping: 'updated_by_name'},
          {name: 'private', mapping: 'private'},
          {name: 'body', mapping: 'body'}
        ]);

      // data reader to parse the json response
      var noteReader = new Ext.data.JsonReader({totalProperty: "total", root: "collection", id: "id"}, NoteRecord);

      // set up connection of the data
      var noteConnection = new Ext.data.Connection({url: #{formatted_party_notes_path(:party_id => @party.id, :format => :json).to_json}, method: 'get'});
      var noteProxy = new Ext.data.HttpProxy(noteConnection);

      // set up the data store and then send request to the server
      var noteDataStore = new Ext.data.Store({
        proxy: noteProxy,
        reader: noteReader,
        baseParams: {q: ''},
        listeners:
          {beforeload: function(store, options){noteGridPanel.disable()},
           load: function(store, records, options){noteGridPanel.enable()}}
      });

      var editRenderer = function(value, cell, record) {
        return '<div class="icon_delete pointerOnHover"/>';
      };


      var addNoteAction = new Ext.Action({
        text:"Add Note",
        iconCls: "display_none",
        handler: function(button, event){
          noteGridPanel.disable();
          createNoteWindow.show();
        }
      });

      // define paging toolbar that is going to be appended to the footer of the grid panel
      var paging = new Ext.PagingToolbar({
        store: noteDataStore,
        pageSize: #{limit},
        displayInfo: true,
        displayMsg: 'Displaying {0} to {1} of {2}',
        emptyMsg: "No record to display",
        cls: "bottom-toolbar paging-toolbar-bottom",
        plugins: [new Ext.ux.PageSizePlugin]
      });

      // create filter field to be appended as the top grid toolbar
      var filterField = new Ext.form.TextField({selectOnFocus: true, grow: false, emptyText: "Search"});
      filterField.on("specialkey",
        function(field, e) {
          if (e.getKey() == Ext.EventObject.RETURN || e.getKey() == Ext.EventObject.ENTER) {
            e.preventDefault();
            ds.baseParams['q'] = this.getValue();
            ds.reload({params: {start: 0, limit: #{limit}}});
          }
        }
      );

      // clear button for the filter field
      var clearButton = new Ext.Toolbar.Button({
        text: 'Clear',
        handler: function() {
          filterField.setValue("");
          ds.baseParams['q'] = "";
          ds.reload();
        }
      });

      var gridTopToolbar = new Ext.Toolbar({
        cls: "top-toolbar",
        items: [{text:"&nbsp;&nbsp;&nbsp;Filter: "}, filterField, clearButton, addNoteAction]
      });

      var privateNoteCheckColumn = new Ext.grid.CheckColumn({
        id: 'private',
        header: "Private",
        dataIndex: 'private',
        width: 14
      });

      var updateNotePath = #{party_note_path(:party_id => @party.id, :id => "__ID__").to_json};

      privateNoteCheckColumn.addListener("click", function(element, event, record){
        var params = {};
        var method = null;
        params["note[private]"] = record.get('private');
        objectId = record.get('id');
        method = "PUT";
        Ext.Ajax.request({
          url: updateNotePath.sub("__ID__", objectId),
          params: params,
          method: method,
          success: function(transport, options){
            response = Ext.util.JSON.decode(transport.responseText);
            record.set('id', response.id);
            record.set('body', response.body);
            record.set('created_at', response.created_at);
            record.set('created_by_name', response.created_by_name);
            record.set('updated_at', response.updated_at);
            record.set('updated_by_name', response.updated_by_name);
            record.set('private', response.private);
            if(response.flash && response.flash.include("Error:"))
              event.grid.getView().getCell(event.row, event.column).highlight({startcolor: "FF5721"});
            else
              event.grid.getView().getCell(event.row, event.column).highlight();
          }
        });
      });

      var noteGridPanel = new Ext.grid.EditorGridPanel({
        title: "Notes",
        store: noteDataStore,
        cm: new Ext.grid.ColumnModel([
            {id: "delete", width: 10, dataIndex: 'id', renderer: editRenderer, sortable: false, menuDisabled: true, hideable: false, tooltip: "Delete row" },
            {id: "note-body", header: "Body",  sortable: true, dataIndex: 'body', editor: new Ext.grid.GridEditor(
              new Ext.form.TextArea({
                preventScrollbar: true,
                selectOnFocus: false
              }),{
                autoSize: true,
                shim:false,
                shadow:false,
                alignment: "tl-tl",
                hideEl : false,
                cls: "x-small-editor x-grid-editor"
              }
            )},
            {id: "created_at", header: "Created At", width: 50, sortable: true, dataIndex: 'created_at'},
            {id: "created_by_name", header: "Created By", width: 30, sortable: true, dataIndex: 'created_by_name'},
            {id: "updated_at", header: "Updated At", width: 50, sortable: true, dataIndex: 'updated_at'},
            {id: "updated_by_name", header: "Updated By", width: 30, sortable: true, dataIndex: 'updated_by_name'},
            privateNoteCheckColumn
          ]),
        autoWidth:true,
        clicksToEdit: 1,
        selModel: new Ext.grid.RowSelectionModel({
          listeners:
            {
              selectionchange: function(selectionModel){
                records = selectionModel.getSelections();
                var ids = new Array();
                records.each( function(e) {
                  ids.push(e.id);
                });
                selectedNoteIds = ids;
              }
            }
        }),
        autoScroll: true,
        tbar: gridTopToolbar,
        bbar: paging,
        footer: true,
        autoExpandColumn: "note-body",
        plugins: privateNoteCheckColumn,
        viewConfig: {
            forceFit: true
        }
      });

      xl.runningGrids.set("#{typed_dom_id(@party, :notes_tab)}", noteGridPanel);
      newPanel.on("destroy", function(){
        xl.runningGrids.unset("#{typed_dom_id(@party, :notes_tab)}");
      });

      noteGridPanel.on("cellclick", function(gr, rowIndex, columnIndex, e) {
        var record = gr.getStore().getAt(rowIndex);
        var id = record.data.id;

        switch(columnIndex){
          case gr.getColumnModel().getIndexById("delete"):
            Ext.Msg.confirm("", "Delete note permanently?", function(btn){
              if ( btn.match(new RegExp("yes","i")) ) {
                var params = {};
                Ext.Ajax.request({
                  url: #{party_note_path(:party_id => @party.id, :id => "__ID__").to_json}.sub("__ID__", id),
                  params: params,
                  method: "DELETE",
                  success: function(transport, options){
                    gr.getStore().reload();
                    response = Ext.util.JSON.decode(transport.responseText);
                    $("status-bar-notifications").innerHTML = response.messages;
                  }
                });
              }
            });
            break;
          default:
            break;
        }
      });

      noteGridPanel.on("validateedit", function(event){
        var record = event.record;
        var editedFieldName = event.field;

        record.set(editedFieldName, event.value);
        var method = "put";
        var objectId = record.get("id");

        var params = {};
        params["note[body]"] = record.get("body");
        params["note[private]"] = record.get("private");

        new Ajax.Request(updateNotePath.sub("__ID__", objectId),{
          method: method,
          parameters: params,
          onSuccess: function(transport){
            response = Ext.util.JSON.decode(transport.responseText);
            record.set('id', response.id);
            record.set('body', response.body);
            record.set('created_at', response.created_at);
            record.set('created_by_name', response.created_by_name);
            record.set('updated_at', response.updated_at);
            record.set('updated_by_name', response.updated_by_name);
            record.set('private', response.private);
            if(response.flash && response.flash.include("Error:"))
              event.grid.getView().getCell(event.row, event.column).highlight({startcolor: "FF5721"});
            else
              event.grid.getView().getCell(event.row, event.column).highlight();
          }
        });

      });

      var createNoteFormPanel = new Ext.form.FormPanel({
        items: [
          new Ext.form.TextArea({
            width: 200,
            fieldLabel: "Body",
            labelSeparator: ":",
            allowBlank: false,
            name: "note[body]",
            value: ""
          })
        ]
      });

      var createNoteWindow = new Ext.Window({
        title: "Create new note",
        items: [createNoteFormPanel],
        height: 145,
        width: 350,
        resizable: false,
        closeAction: 'hide',
        listeners:{hide: function(panel){noteGridPanel.enable();}},
        buttons:[
            {
              text: "Create",
              handler: function() {
                  createNoteFormPanel.getForm().doAction("submit",
                    {
                      url: #{party_notes_path(:party_id => @party.id).to_json},
                      method: "POST",
                      success: function(form, action){
                        noteGridPanel.getStore().reload();
                      },
                      failure: function(form, action){
                        response = action.result
                        Ext.Msg.show({
                          title: "Saving failed",
                          msg: response.messages,
                          buttons: Ext.Msg.OK,
                          minWidth: 750
                        })
                      }
                    }
                  )
                  if(createNoteFormPanel.getForm().isValid()) {
                    noteGridPanel.enable();
                    createNoteWindow.hide();
                  }
                }
            },
            {
              text: 'Cancel',
              handler: function() {
                noteGridPanel.enable();
                createNoteWindow.hide();
              }
            }
          ]
      });
      noteDataStore.load();
    `
  end

  def initialize_files_panel
    %Q`
      #{initialize_pictures_panel}
      #{initialize_multimedia_panel}
      #{initialize_other_files_panel}

      var attachImageButton = new Ext.Button({
          text: 'Attach image(s)',
          handler: function(button, event) {
            xl.widget.OpenImagePicker({
              showFrom: button.getId(),
              objectId: #{@party.id},
              objectType: 'party',

              thisObjectImagesUrl: #{images_party_path(@party).to_json},
              allImagesUrl: #{formatted_image_picker_assets_path(:format => :json).to_json},

              uploadUrl: #{upload_image_party_path(:id => @party.id).to_json},

              afterUpdate: function(xhr, options, record, allImagesStore, thisObjectImagesStore) {
                picturePanelStore.reload();
              }
            });
          }
      });

      var attachMultimediaButton = new Ext.Button({
        text: 'Attach multimedia file(s)',
        hidden: true,
        handler: function(button, event) {
          xl.widget.OpenImagePicker({
            showFrom: button.getId(),
            objectId: #{@party.id},
            objectType: 'party',
            imageClassification: 'multimedia',
            windowTitle: "Multimedia Picker",

            thisObjectImagesUrl: #{multimedia_party_path(@party).to_json},
            allImagesUrl: #{formatted_image_picker_assets_path(:content_type => "multimedia", :format => :json).to_json},

            afterUpdate: function(xhr, options, record, allImagesStore, thisObjectImagesStore) {
              multimediaPanelStore.reload()
            }
          });
        }
      });

      var attachOtherFileButton = new Ext.Button({
        text: 'Attach other file(s)',
        hidden: true,
        handler: function(button, event) {
          xl.widget.OpenImagePicker({
            showFrom: button.getId(),
            objectId: #{@party.id},
            objectType: 'party',
            imageClassification: 'other_files',
            windowTitle: "Other Files Picker",

            thisObjectImagesUrl: #{other_files_party_path(@party).to_json},
            allImagesUrl: #{formatted_image_picker_assets_path(:content_type => "others", :format => :json).to_json},

            afterUpdate: function(xhr, options, record, allImagesStore, thisObjectImagesStore) {
              otherFilePanelStore.reload()
            }
          });
        }
      });

      var fileTypeStore = new Ext.data.SimpleStore({
        fields: ['display'],
        data: [['Pictures'], ['Multimedia'], ['Other Files']]
      });

      var chooseFileTypeComboBox = new Ext.form.ComboBox({
        displayField: 'display',
        fieldLabel: 'File Type',
        value: 'Pictures',
        store: fileTypeStore,
        editable : false,
        triggerAction: 'all',
        mode: 'local',
        listeners: {
          select: function(combo, record, index){
            if(record.data.display == "Other Files"){
              picturesPanel.hide();
              attachImageButton.hide();
              multimediaPanel.hide();
              attachMultimediaButton.hide();
              otherFilesPanel.show();
              attachOtherFileButton.show();
              otherFilePanel.view.refresh();
            }
            else if(record.data.display == "Multimedia"){
              picturesPanel.hide();
              attachImageButton.hide();
              multimediaPanel.show();
              attachMultimediaButton.show();
              otherFilesPanel.hide();
              attachOtherFileButton.hide();
              multimediaGridPanel.view.refresh();
            }
            else{
              picturesPanel.show();
              attachImageButton.show();
              multimediaPanel.hide();
              attachMultimediaButton.hide();
              otherFilesPanel.hide();
              attachOtherFileButton.hide();
              picturePanel.view.refresh();
            }
          }
        }
      });

      var filePanelTopToolbar = new Ext.Toolbar({
        cls: "top-toolbar",
        items: [chooseFileTypeComboBox, {text:"&nbsp;&nbsp;&nbsp;"}, attachImageButton, attachMultimediaButton, attachOtherFileButton]
      });

      var filesPanel = new Ext.Panel({
        tbar: filePanelTopToolbar,
        items: [picturesPanel, multimediaPanel, otherFilesPanel]
      });
    `
  end

  def initialize_pictures_panel
    %Q`
      var picturePanelStore = new Ext.data.JsonStore({
        url: #{images_party_path(:id => @party.id, :size => "mini").to_json},
        root: "collection",
        fields: ["filename", "url", "id"]
      });

      picturePanelStore.load();

      var picturePanelTemplate = new Ext.XTemplate(
        '<tpl for=".">',
          '<div class="picture-thumb-wrap">',
            '<div class="picture-thumb"><img src="{url}" title="{filename}"/></div>',
            '<div class="picture-thumb-filename">{filename}</div>',
          '</div>',
        '</tpl>'
      );

      var picturePanel = new Ext.Panel({
        title: "PICTURES",
        items: [new Ext.DataView({
          store: picturePanelStore,
          tpl: picturePanelTemplate,
          overClass: 'x-view-over',
          itemSelector: 'div.picture-thumb-wrap',
          emptyText: "No pictures to display"
        })]
      });

      var imageViewerResult = xl.widget.ImageViewer({
        objectId: #{@party.id},
        objectType: 'party',
        height: xl.centerPanel.getInnerHeight()-xl.centerPanel.getBottomToolbar().getSize().height-78,
        imagesUrl: #{images_party_path(@party).to_json}
      });

      var picturePanel = imageViewerResult[0];
      var picturePanelStore = imageViewerResult[1];

      var picturesPanel = new Ext.Panel({
        items: [picturePanel]
      });
    `
  end

  def initialize_multimedia_panel
    %Q`
      var multimediaPanelStore = new Ext.data.JsonStore({
        url: #{multimedia_party_path(:id => @party.id, :size => "mini").to_json},
        root: "collection",
        fields: ["filename", "url", "id"]
      });

      multimediaPanelStore.load();

      var multimediaPanelTemplate = new Ext.XTemplate(
        '<tpl for=".">',
          '<div class="picture-thumb-wrap">',
            '<div class="picture-thumb"><img src="{url}" title="{filename}"/></div>',
            '<div class="picture-thumb-filename">{filename}</div>',
          '</div>',
        '</tpl>'
      );

      var multimediaPanel = new Ext.Panel({
        title: "MULTIMEDIA",
        items: [new Ext.DataView({
          store: multimediaPanelStore,
          tpl: multimediaPanelTemplate,
          overClass: 'x-view-over',
          itemSelector: 'div.picture-thumb-wrap',
          emptyText: "No multimedia to display"
        })]
      });

      var imageViewerResult = xl.widget.ImageViewer({
        objectId: #{@party.id},
        objectType: 'party',

        imagesUrl: #{multimedia_party_path(@party).to_json}
      });

      var multimediaGridPanel = imageViewerResult[0];
      var multimediaPanelStore = imageViewerResult[1];

      var multimediaPanel = new Ext.Panel({
        hidden: true,
        items: [multimediaGridPanel]
      });
    `
  end

  def initialize_other_files_panel
    %Q`
      var otherFilePanelStore = new Ext.data.JsonStore({
        url: #{other_files_party_path(:id => @party.id, :size => "mini").to_json},
        root: "collection",
        fields: ["filename", "url", "id"]
      });

      otherFilePanelStore.load();

      var otherFilePanelTemplate = new Ext.XTemplate(
        '<tpl for=".">',
          '<div class="picture-thumb-wrap">',
            '<div class="picture-thumb"><img src="{url}" title="{filename}"/></div>',
            '<div class="picture-thumb-filename">{filename}</div>',
          '</div>',
        '</tpl>'
      );

      var otherFilePanel = new Ext.Panel({
        title: "OTHER FILES",
        items: [new Ext.DataView({
          store: otherFilePanelStore,
          tpl: otherFilePanelTemplate,
          overClass: 'x-view-over',
          itemSelector: 'div.picture-thumb-wrap',
          emptyText: "No files to display"
        })]
      });

      var imageViewerResult = xl.widget.ImageViewer({
        objectId: #{@party.id},
        objectType: 'party',

        imagesUrl: #{other_files_party_path(@party).to_json}
      });

      var otherFilePanel = imageViewerResult[0];
      var otherFilePanelStore = imageViewerResult[1];

      var otherFilesPanel = new Ext.Panel({
        hidden: true,
        items: [otherFilePanel]
      });
    `
  end

  def initialize_settings_panel
    %Q`
      var oldPasswordField = new Ext.form.TextField({
        allowBlank: false,
        name: "old_password",
        fieldLabel: "Old Password",
        inputType: "password"
      });

      var newPasswordField = new Ext.form.TextField({
        allowBlank: false,
        name: "password",
        fieldLabel: "New Password",
        inputType: "password"
      });

      var newPasswordConfirmationField = new Ext.form.TextField({
        allowBlank: false,
        name: "password_confirmation",
        fieldLabel: "New Password Confirmation",
        inputType: "password"
      });

      var changePasswordFormPanel = new Ext.form.FormPanel({
        title: "Password",
        collapsible: true,
        items: [oldPasswordField, newPasswordField, newPasswordConfirmationField],
        buttons: [
          {
            text: "OK",
            handler: function(button, event){
              changePasswordFormPanel.getForm().doAction('submit', {
                url: #{change_password_party_path(:id => @party.id).to_json},
                method: "PUT",
                waitMsg: "Processing change password...",
                success: function(form, action){
                  Ext.Msg.alert("Change password", action.result.popup_messages);
                  oldPasswordField.setValue("");
                  newPasswordField.setValue("");
                  newPasswordConfirmationField.setValue("");
                },
                failure: function(form, action){
                  Ext.Msg.alert("Change password", action.result.popup_messages);
                  oldPasswordField.setValue("");
                  newPasswordField.setValue("");
                  newPasswordConfirmationField.setValue("");
                }
              });
            }
          },
          {
            text: "Clear",
            handler: function(button, event){
              oldPasswordField.setValue("");
              newPasswordField.setValue("");
              newPasswordConfirmationField.setValue("");
            }
          },
          {
            text: "Reset Password",
            handler: function(button, event){
              Ext.Msg.confirm("Reset Password", "Are you sure?", function(btn){
                if ( btn.match(new RegExp("yes","i")) ) {
                  var params = {};
                  params["reset"] = true;
                  Ext.Msg.wait("Resetting password...");
                  Ext.Ajax.request({
                    url: #{change_password_party_path(:id => @party.id).to_json},
                    params: params,
                    method: "PUT",
                    success: function(transport, options){
                      response = Ext.util.JSON.decode(transport.responseText);
                      Ext.Msg.alert("Reset Password", response.popup_messages);
                    }
                  });
                }
              });
            }
          }
        ]
      });

      var profileCommentsCheckbox = new Ext.form.Checkbox({
        fieldLabel: "Comments on my Profile",
        name: "profile_comment_notification",
        checked: #{@party.profile_comment_notification.to_json},
        type: 'checkbox',
        listeners: {
          'check': function(me, checked){
            var parameters = {};
            parameters["party[profile_comment_notification]"] = checked;
            
            Ext.Ajax.request({
              url: #{party_path(@party).to_json},
              params: parameters,
              method: "PUT"
            });
          }
        }
      });

      var blogPostCommentsCheckbox = new Ext.form.Checkbox({
        fieldLabel: "Comments on my Blog Posts",
        name: "blog_post_comment_notification",
        checked: #{@party.blog_post_comment_notification.to_json},
        type: 'checkbox',
        listeners: {
          'check': function(me, checked){
            var parameters = {};
            parameters["party[blog_post_comment_notification]"] = checked;
            
            Ext.Ajax.request({
              url: #{party_path(@party).to_json},
              params: parameters,
              method: "PUT"
            });
          }
        }
      });

      var listingCommentsCheckbox = new Ext.form.Checkbox({
        fieldLabel: "Comments on my Listings",
        name: "listing_comment_notification",
        checked: #{@party.listing_comment_notification.to_json},
        type: 'checkbox',
        listeners: {
          'check': function(me, checked){
            var parameters = {};
            parameters["party[listing_comment_notification]"] = checked;
            
            Ext.Ajax.request({
              url: #{party_path(@party).to_json},
              params: parameters,
              method: "PUT"
            });
          }
        }
      });

      var productCommentsCheckbox = new Ext.form.Checkbox({
        fieldLabel: "Comments on my Product",
        name: "product_comment_notification",
        checked: #{@party.product_comment_notification.to_json},
        type: 'checkbox',
        listeners: {
          'check': function(me, checked){
            var parameters = {};
            parameters["party[product_comment_notification]"] = checked;
            
            Ext.Ajax.request({
              url: #{party_path(@party).to_json},
              params: parameters,
              method: "PUT"
            });
          }
        }
      });
      
      var emailNotificationsPanel = new Ext.Panel({
        layout: 'form',
        labelWidth: 175,
        title: "Email Notifications",
        items:[
          {html: "<p>Send me an email notification when someone:</p><br />"},
          blogPostCommentsCheckbox, 
          listingCommentsCheckbox, 
          productCommentsCheckbox, 
          profileCommentsCheckbox
        ]
      });
      
      var settingsPanel =  new Ext.Panel({
        items: [changePasswordFormPanel, emailNotificationsPanel]
      });
    `
  end

  def render_contact_route_grid_options
    %Q`
      viewConfig: {
          forceFit: true
      },
      autoScroll: true,
      autoWidth: true,
      clicksToEdit:1
    `
  end

  def render_grid_name_combobox
    %Q`
      new Ext.form.ComboBox({
        store: namesStore,
        displayField: 'value',
        triggerAction: 'all',
        editable: true,
        mode: 'local',
        listeners: {
          'focus': {
            fn: function(me){
              me.selectText();
            }
          }
        }
      })
    `
  end

  def render_grid_textfield
    %Q`
      new Ext.form.TextField({
        listeners: {
          'focus': {
            fn: function(me){
              me.selectText();
            }
          }
        }
      })
    `
  end

  def initialize_permissions_panel
    %Q`
      /////////////////////////////////////////CREATE EFFECTIVE PERMISSIONS GRID///////////////////////////////////////////////////

      var EffectivePermissionRecord = new Ext.data.Record.create([
        {name: 'id', mapping: 'id'},
        {name: 'name', mapping: 'name'}
      ]);

      var formattedEffectivePermissionsPath = #{formatted_effective_permissions_party_path(:id => @party.id, :format => "json").to_json};

      // data reader to parse the json response
      var effectivePermissionsReader = new Ext.data.JsonReader({totalProperty: "total", root: "collection", id: "id"}, EffectivePermissionRecord);

      // set up connection of the data
      var effectivePermissionsConnection = new Ext.data.Connection({url: formattedEffectivePermissionsPath, method: 'get'});
      var effectivePermissionsProxy = new Ext.data.HttpProxy(effectivePermissionsConnection);

      // set up the data store and then send request to the server
      var effectivePermissionsDataStore = new Ext.data.Store({
        proxy: effectivePermissionsProxy,
        reader: effectivePermissionsReader
      });

      var effectivePermissionsGridPanel = new Ext.grid.GridPanel({
        title: "Effective Permissions",
        store: effectivePermissionsDataStore,
        cm: new Ext.grid.ColumnModel([
            {id: "effective-permission-name", header: "Name", dataIndex: 'name'}
          ]),
        disableSelection: true,
        width: (#{get_center_panel_width}/2-9),
        height: #{get_default_grid_height(nil)}-30,
        viewConfig: {autoFill: true},
        autoExpandColumn: "effective-permission-name",
        frame: true,
        loadMask: true
      });

      xl.runningGrids.set("#{typed_dom_id(@party, :effective_permissions)}", effectivePermissionsGridPanel);
      newPanel.on("destroy", function(){
        xl.runningGrids.unset("#{typed_dom_id(@party, :effective_permissions)}");
      });

      /////////////////////////////////////////END CREATE EFFECTIVE PERMISSIONS GRID////////////////////////////////////////////////


      /////////////////////////////////////////CREATE SELECT PERMISSIONS GRID///////////////////////////////////////////////////

      var SelectPermissionRecord = new Ext.data.Record.create([
        {name: 'id', mapping: 'id'},
        {name: 'selected', mapping: 'selected'},
        {name: 'name', mapping: 'name'}
      ]);

      var formattedSelectPermissionsPath = #{@formatted_selected_permissions_path.to_json};

      // data reader to parse the json response
      var selectPermissionsReader = new Ext.data.JsonReader({totalProperty: "total", root: "collection", id: "id"}, SelectPermissionRecord);

      // set up connection of the data
      var selectPermissionsConnection = new Ext.data.Connection({url: formattedSelectPermissionsPath, method: 'get'});
      var selectPermissionsProxy = new Ext.data.HttpProxy(selectPermissionsConnection);

      // set up the data store and then send request to the server
      var selectPermissionsDataStore = new Ext.data.Store({
        proxy: selectPermissionsProxy,
        reader: selectPermissionsReader
      });

      var selectPermissionsCheckColumn = new Ext.grid.CheckColumn({
        header: " ",
        dataIndex: 'selected',
        width: 25
      });

      selectPermissionsCheckColumn.addListener("click", function(element, event, record){
        var params = {};
        var method = null;
        var url = null;
        params["subject_type"] = "Permission";
        params["subject_ids"] = record.id;
        if(record.get("selected")){
          method = "POST";
          url = #{@permission_grants_path.to_json};
        }
        else{
          method = "DELETE";
          url = #{@destroy_collection_permission_grants_path.to_json};
        }
        Ext.Ajax.request({
          url: url,
          params: params,
          method: method,
          success: function(response, options){
            effectivePermissionsDataStore.reload();
          }
        });
      });

      var selectAllAction = new Ext.Action({
        text: "Select All",
        handler: function(){
          permissionsPanel.el.mask("Processing...");
          var records = selectPermissionsDataStore.getRange(0, selectPermissionsDataStore.getCount()-1);
          var record_ids = new Array();
          for(i=0;i<records.size();i++){
            record_ids.push(records[i].get("id"));
          };
          var params = {};
          params["subject_type"] = "Permission";
          params["subject_ids"] = record_ids.join(",");
          Ext.Ajax.request({
            url: #{@permission_grants_path.to_json},
            params: params,
            method: "POST",
            success: function(response, options){
              selectPermissionsDataStore.reload();
              effectivePermissionsDataStore.reload();
            }
          });
          permissionsPanel.el.unmask();
        }
      });

      var clearAllAction = new Ext.Action({
        text: "Clear All",
        handler: function(){
          permissionsPanel.el.mask("Processing...");
          var records = selectPermissionsDataStore.getRange(0, selectPermissionsDataStore.getCount()-1);
          var record_ids = new Array();
          for(i=0;i<records.size();i++){
            record_ids.push(records[i].get("id"));
          };
          var params = {};
          params["subject_type"] = "Permission";
          params["subject_ids"] = record_ids.join(",");
          Ext.Ajax.request({
            url: #{@destroy_collection_permission_grants_path.to_json},
            params: params,
            method: "DELETE",
            success: function(response, options){
              selectPermissionsDataStore.reload();
              effectivePermissionsDataStore.reload();
            }
          });
          permissionsPanel.el.unmask();
        }
      });

      var selectPermissionsGridPanel = new Ext.grid.EditorGridPanel({
        title: "Selected Permissions",
        store: selectPermissionsDataStore,
        cm: new Ext.grid.ColumnModel([
            selectPermissionsCheckColumn,
            {id: "select-permission-name", header: "Name", dataIndex: 'name'}
          ]),
        width: (#{get_center_panel_width}/2),
        height: ((#{get_default_grid_height(nil)}-30)/2),
        plugins: selectPermissionsCheckColumn,
        viewConfig: {autoFill: true},
        tbar: [selectAllAction, clearAllAction],
        autoExpandColumn: "select-permission-name",
        frame: true
      });

      xl.runningGrids.set("#{typed_dom_id(@party, :select_permissions)}", selectPermissionsGridPanel);
      newPanel.on("destroy", function(){
        xl.runningGrids.unset("#{typed_dom_id(@party, :select_permissions)}");
      });

      /////////////////////////////////////////END CREATE SELECT PERMISSIONS GRID////////////////////////////////////////////////

      /////////////////////////////////////////CREATE DENIED PERMISSIONS GRID///////////////////////////////////////////////////

      var DeniedPermissionRecord = new Ext.data.Record.create([
        {name: 'id', mapping: 'id'},
        {name: 'checked', mapping: 'checked'},
        {name: 'name', mapping: 'name'}
      ]);

      var formattedPermissionDenialsPath = #{@formatted_permission_denials_path.to_json};

      // data reader to parse the json response
      var deniedPermissionsReader = new Ext.data.JsonReader({totalProperty: "total", root: "collection", id: "id"}, EffectivePermissionRecord);

      // set up connection of the data
      var deniedPermissionsConnection = new Ext.data.Connection({url: formattedPermissionDenialsPath, method: 'get'});
      var deniedPermissionsProxy = new Ext.data.HttpProxy(deniedPermissionsConnection);

      // set up the data store and then send request to the server
      var deniedPermissionsDataStore = new Ext.data.Store({
        proxy: deniedPermissionsProxy,
        reader: deniedPermissionsReader
      });

      var deniedPermissionsCheckColumn = new Ext.grid.CheckColumn({
        header: " ",
        dataIndex: 'checked',
        width: 5
      });

      deniedPermissionsCheckColumn.addListener("click", function(element, event, record){
        var params = {};
        var method = null;
        var url = null;
        params["subject_type"] = "Permission";
        params["subject_ids"] = record.id;
        if(record.get("checked")){
          url = #{@permission_denials_path.to_json};
          method = "POST"
        }
        else{
          url = #{@destroy_collection_permission_denials_path.to_json};
          method = "DELETE";
        }
        Ext.Ajax.request({
          url: url,
          params: params,
          method: method,
          success: function(response, options){
            effectivePermissionsDataStore.reload();
          }
        });
      });

      var deniedPermissionsGridPanel = new Ext.grid.EditorGridPanel({
        title: "Denied Permissions",
        store: deniedPermissionsDataStore,
        cm: new Ext.grid.ColumnModel([
            deniedPermissionsCheckColumn,
            {id: "denied-permission-name", header: "Name", dataIndex: 'name'}
          ]),
        width: (#{get_center_panel_width}/2),
        height: ((#{get_default_grid_height(nil)}-30)/2-1),
        plugins: deniedPermissionsCheckColumn,
        viewConfig: {autoFill: true},
        autoExpandColumn: "denied-permission-name",
        frame: true
      });

      xl.runningGrids.set("#{typed_dom_id(@party, :denied_permissions)}", deniedPermissionsGridPanel);
      newPanel.on("destroy", function(){
        xl.runningGrids.unset("#{typed_dom_id(@party, :denied_permissions)}");
      });

      /////////////////////////////////////////END CREATE DENIED PERMISSIONS GRID////////////////////////////////////////////////

      var permissionsPanel = new Ext.Panel({
        layout: "table",
        layoutConfig: {columns: 2},
        items:[
          {rowspan:2, items:[effectivePermissionsGridPanel]},
          {items:[selectPermissionsGridPanel]},
          {items:[deniedPermissionsGridPanel]}
        ]
      });

      effectivePermissionsDataStore.load();
      deniedPermissionsDataStore.load();
      selectPermissionsDataStore.load();
    `
  end

  def initialize_memberships_panel
    %Q`
      var membershipsRootTreeNode =  new Ext.tree.AsyncTreeNode({
        text: "Group - Root",
        expanded: true,
        id: 0
      });

      var membershipsFileTreePanel = new Ext.tree.TreePanel({
        title: "Groups",
        root: membershipsRootTreeNode,
        rootVisible: false,
        autoScroll: true,
        height: ((#{get_default_grid_height(nil)}-30)/2-1),
        loader: new Ext.tree.TreeLoader({
          requestMethod: "GET",
          url: #{formatted_groups_path(:party_id => @party.id, :format => :json).to_json},
          baseAttrs: {uiProvider: Ext.tree.TreeCheckNodeUI}
        }),
        listeners: {
            check: function(node, checked){
              var params = {};
              var method = null;
              params["party_id"] = #{@party.id};
              params["group_id"] = node.id;
              if(checked){
                method = "POST"
              }
              else{
                method = "DELETE";
              }
              Ext.Ajax.request({
                url: #{memberships_path.to_json},
                params: params,
                method: method,
                success: function(response, options){
                }
              });
            },
            click: function(node, event){
              groupTreePermissionsConnection.url = formattedPermissionGrantsPath.sub("__ID__", node.id);
              groupTreePermissionsDataStore.reload();
            }
          }
      });

      var rolesRootTreeNode =  new Ext.tree.AsyncTreeNode({
        text: "Role - Root",
        expanded: true,
        id: 0
      });

      var rolesFileTreePanel = new Ext.tree.TreePanel({
        title: "Roles",
        root: rolesRootTreeNode,
        rootVisible: false,
        height: ((#{get_default_grid_height(nil)}-30)/2-1),
        autoScroll: true,
        loader: new Ext.tree.TreeLoader({
          requestMethod: "GET",
          url: #{formatted_roles_path(:party_id => @party.id, :format => :json).to_json},
          baseAttrs: {uiProvider: Ext.tree.TreeCheckNodeUI}
        }),
        listeners: {
            check: function(node, checked){
              var params = {};
              var method = null;
              var url = null
              params["subject_type"] = "Role";
              params["subject_ids"] = node.id;
              if(checked){
                method = "POST";
                url = #{@permission_grants_path.to_json};
              }
              else{
                method = "DELETE";
                url = #{@destroy_collection_permission_grants_path.to_json};
              }
              Ext.Ajax.request({
                url: url,
                params: params,
                method: method
              });
            },
            click: function(node, event){
              groupTreePermissionsConnection.url = #{@formatted_total_role_permission_grants_path.to_json}.sub("__ID__", node.id);
              groupTreePermissionsDataStore.reload();
            }
          }
      });

      ////////////////////////////////////////////CREATE GROUP PERMISSIONS GRID////////////////////////////////////////////////

      // create permission record
      var PermissionRecord = new Ext.data.Record.create([
        {name: 'id', mapping: 'id'},
        {name: 'name', mapping: 'name'}
      ]);

      var formattedPermissionGrantsPath = #{@formatted_total_group_permission_grants_path.to_json};

      // data reader to parse the json response
      var groupTreePermissionsReader = new Ext.data.JsonReader({totalProperty: "total", root: "collection", id: "id"}, PermissionRecord);

      // set up connection of the data
      var groupTreePermissionsConnection = new Ext.data.Connection({url: formattedPermissionGrantsPath, method: 'get'});
      var groupTreePermissionsProxy = new Ext.data.HttpProxy(groupTreePermissionsConnection);

      // set up the data store and then send request to the server
      var groupTreePermissionsDataStore = new Ext.data.Store({proxy: groupTreePermissionsProxy, reader: groupTreePermissionsReader});

      var groupTreePermissionsGridPanel = new Ext.grid.GridPanel({
        store: groupTreePermissionsDataStore,
        cm: new Ext.grid.ColumnModel([
            {id: "permission-name", header: "Name", dataIndex: 'name'}
          ]),
        height: #{get_default_grid_height(nil)}-60,
        selModel: new Ext.grid.RowSelectionModel,
        viewConfig: {forceFit: true}
      });

      xl.runningGrids.set("#{typed_dom_id(@party, :memberships)}", groupTreePermissionsGridPanel);
      newPanel.on("destroy", function(){
        xl.runningGrids.unset("#{typed_dom_id(@party, :memberships)}");
      });

      //////////////////////////////////////////END CREATE GROUP PERMISSIONS GRID//////////////////////////////////////////////

      var membershipsPanel = new Ext.Panel({
        layout: "column",
        items: [
          {columnWidth: .5, items:[membershipsFileTreePanel, rolesFileTreePanel]},
          {title: "Related Permissions", columnWidth: .5, items:[groupTreePermissionsGridPanel]}
        ]
      });
    `
  end

  def initialize_contact_details_panel
    avatar_path = nil
    if @party.avatar
      avatar_path = download_asset_path(:id => @party.avatar.id, :size => "mini")
    else
      avatar_path = "/images/Mr-Smith.jpg"
    end

    avatar_image_tag = %Q`<img src="#{avatar_path}" id="#{typed_dom_id(@party, :avatar_img_tag)}"/>`

    %Q`
      #{self.create_countries_and_states_store}

      var updatePartyForm = {url: #{party_path(@party).to_json}, object: 'party'};

      var modifiedByPanel = new Ext.Panel({
        style: "padding-bottom: 3px",
        html: #{self.render_record_modifier.to_json}
      });

      var avatarPanel = new Ext.Panel({
        style: "padding:10px",
        autoShow: true,
        items: {html: "<center>" + #{avatar_image_tag.to_json} + "</center>"},
        tbar: [
          {
            text: "Edit Profile",
            listeners: {
              click: function(button, event){
                Ext.Ajax.request({
                  url: #{edit_profile_path(@party).to_json},
                  method: "GET"
                });
              }
            }
          }
        ],
        bbar:[
          {
            text: "Change/Upload picture",
            listeners: {
              click: function(button, event){
                xl.widget.OpenSingleImagePicker(#{typed_dom_id(@party, :avatar_img_tag).to_json}, #{formatted_image_picker_assets_path(:format => :json).to_json}, "Party", #{@party.id}, {
                  setAvatar: true,
                  setRelation: true,
                  windowTitle: "Please select your avatar...",
                  beforeSelect: function(window){
                    window.el.mask("Processing...");
                  },
                  afterSelect: function(selectedRecord, window){
                    var params = {};
                    params["party[avatar_id]"] = selectedRecord.id;
                    Ext.Ajax.request({
                      url: #{party_path(@party).to_json},
                      method: "PUT",
                      params: params,
                      success: function(response, options){
                        window.el.unmask();
                      }
                    });
                    Ext.Ajax.request({
                      url: #{add_views_path.to_json},
                      params: {id: selectedRecord.get("id"), classification: "Image", object_type: "Party", object_id: #{@party.id}},
                      method: "POST",
                      success: function(response, options){
                        picturePanelStore.reload();
                      }
                    });
                  }
                });
              }
            }
          }
        ]
      });

      #{self.render_tags_panel("party[tag_list]", @party, current_account.parties.tags, {:inline_form => "updatePartyForm"})}

      var honorificsStore = new Ext.data.SimpleStore({
        fields: ['display'],
        data: [["Mr."], ["Mrs."], ["Ms"]]
      });

      #{self.create_date_selection_data_stores}

      var birthdateDayField = xl.widget.InlineActiveField({
        form: updatePartyForm,
        field:{
          value: #{@party.birthdate_day.to_s.to_json},
          name: "birthdate_day",
          hiddenName: "party[birthdate_day]",
          displayField: "display",
          valueField: "value",
          id: #{typed_dom_id(@party, :birthdate_day).to_json},
          fieldLabel: "Birthdate",
          type: "combobox",
          store: daysStore,
          triggerAction: "all",
          mode: "local",
          width: 50,
          listWidth: 50
        }
      });

      var birthdateMonthField = xl.widget.InlineActiveField({
        form: updatePartyForm,
        field:{
          value: #{@party.birthdate_month.to_s.to_json},
          name: "birthdate_month",
          hiddenName: "party[birthdate_month]",
          displayField: "display",
          valueField: "value",
          id: #{typed_dom_id(@party, :birthdate_month).to_json},
          type: "combobox",
          store: monthsStore,
          triggerAction: "all",
          mode: "local",
          width: 85,
          listWidth: 85,
          hideLabel: true
        }
      });

      var birthdateYearField = xl.widget.InlineActiveField({
        form: updatePartyForm,
        field:{
          value: #{@party.birthdate_year.to_s.to_json},
          name: "birthdate_year",
          hiddenName: "party[birthdate_year]",
          displayField: "display",
          valueField: "value",
          id: #{typed_dom_id(@party, :birthdate_year).to_json},
          type: "combobox",
          store: yearsStore,
          triggerAction: "all",
          mode: "local",
          width: 55,
          listWidth: 55,
          hideLabel: true
        }
      });

      var birthdateField = new Ext.Panel({
        layout: 'table',
        layoutConfig: {
          columns: 3
        },
        items: [{layout: "form", style: "margin-top:3px", items: birthdateDayField}, birthdateMonthField, birthdateYearField]
      });

      var contactDetailsMiddlePanel = new Ext.Panel({
        width: 300,
        layout: "form",
        items:[
            xl.widget.InlineActiveField({
              form: updatePartyForm,
              field: {
                value: #{@party.honorific.to_json},
                name: 'honorific',
                displayField: "display",
                fieldLabel: 'Honorific',
                id: #{typed_dom_id(@party, :honorific).to_json},
                type: 'combobox',
                store: honorificsStore,
                triggerAction: 'all',
                mode: 'local'
              }
            }),
            xl.widget.InlineActiveField({ form: updatePartyForm, field: {value: #{@party.first_name.to_json}, name: 'first_name', fieldLabel: 'First Name', id: #{typed_dom_id(@party, :first_name).to_json}}}),
            xl.widget.InlineActiveField({ form: updatePartyForm, field: {value: #{@party.middle_name.to_json}, name: 'middle_name', fieldLabel: 'Middle Name', id: #{typed_dom_id(@party, :middle_name).to_json}}}),
            xl.widget.InlineActiveField({ form: updatePartyForm, field: {value: #{@party.last_name.to_json}, name: 'last_name', fieldLabel: 'Last Name', id: #{typed_dom_id(@party, :last_name).to_json}}}),
            xl.widget.InlineActiveField({ form: updatePartyForm, field: {value: #{@party.company_name.to_json}, name: 'company_name', fieldLabel: 'Company Name', id: #{typed_dom_id(@party, :company_name).to_json}}}),
            xl.widget.InlineActiveField({ form: updatePartyForm, field: {value: #{@party.position.to_json}, name: 'position', fieldLabel: 'Position', id: #{typed_dom_id(@party, :position).to_json}}}),
            birthdateField
        ]
      });

      var contactDetailsTopRightPanel = new Ext.Panel({
        title: "Quick Description",
        collapsible: true,
        style: 'margin-left: 10px',
        width: 250,
        html: #{render(:partial => "main_contact_routes").to_json}
      })

      var contactDetailsTopPanel = new Ext.Panel({
        style: "padding-top: 6px; padding-bottom: 3px",
        layout: "column",
        items:[ avatarPanel, contactDetailsMiddlePanel, contactDetailsTopRightPanel]
      });

      var contactDetailsPanel = new Ext.Panel({
        items: [contactDetailsTopPanel, modifiedByPanel, tagsPanel]
      });
    `
  end

  def initialize_contact_routes_panel
    %Q`

      var namesStore = new Ext.data.SimpleStore({
        fields: ['value'],
        data: [['Main'], ['Business'], ['Home'], ['Office'], ['Work'], ['Other']]
      });

      var phoneNamesStore = new Ext.data.SimpleStore({
        fields: ['value'],
        data: [['Main'], ['Business'], ['Cell'], ['Home'], ['Fax'], ['Mobile'], ['Office'], ['Work'], ['Other']]
      });

      #{self.initialize_address_grid_panel}
      #{self.initialize_email_grid_panel}
      #{self.initialize_phone_grid_panel}
      #{self.initialize_link_grid_panel}

      var addAddressAction = new Ext.Action({
        text:"Add Address",
        iconCls: "display_none",
        handler: function(button, event){
          addressGridPanel.disable();
          createAddressWindow.show();
        }
      });

      var addEmailAction = new Ext.Action({
        text:"Add Email",
        iconCls: "display_none",
        handler: function(button, event){
          emailGridPanel.disable();
          createEmailWindow.show();
        }
      });

      var addPhoneAction = new Ext.Action({
        text:"Add Phone",
        iconCls: "display_none",
        handler: function(button, event){
          phoneGridPanel.disable();
          createPhoneWindow.show();
        }
      });

      var addLinkAction = new Ext.Action({
        text:"Add Link",
        iconCls: "display_none",
        handler: function(button, event){
          linkGridPanel.disable();
          createLinkWindow.show();
        }
      });

      var addRoutesMenu =  new Ext.menu.Menu({
        items: [addAddressAction, addEmailAction, addPhoneAction, addLinkAction]
      });

      var contactRoutesPanel = new Ext.Panel({
        title: "Contact Routes",
        tbar: [
          {
            text:"Add",
            menu: addRoutesMenu
          }
        ],
        defaults: { style: "padding-bottom: 20px"},
        layout: 'column',
        items:[
          addressGridPanel
          ,emailGridPanel
          ,phoneGridPanel
          ,linkGridPanel       
        ],
        autoScroll:true
      });
    `
  end

  def initialize_link_grid_panel
    %Q`
      var selectedLinkIds = null;

      var LinkRecord = new Ext.data.Record.create([
          {name: 'id', mapping: 'id'},
          {name: 'name', mapping: 'name'},
          {name: 'url', mapping: 'url'}
        ]);

      // data reader to parse the json response
      var linkReader = new Ext.data.JsonReader({totalProperty: "total", root: "collection", id: "id"}, LinkRecord);

      // set up connection of the data
      var linkConnection = new Ext.data.Connection({url: #{formatted_party_links_path(:party_id => @party.id, :format => :json).to_json}, method: 'get'});
      var linkProxy = new Ext.data.HttpProxy(linkConnection);

      // set up the data store and then send request to the server
      var linkDataStore = new Ext.data.Store({
        proxy: linkProxy,
        reader: linkReader,
        baseParams: {q: ''},
        listeners:
          {beforeload: function(store, options){linkGridPanel.disable()},
           load: function(store, records, options){linkGridPanel.enable()}}
      });

      var editRenderer = function(value, cell, record) {
        return '<div class="icon_delete pointerOnHover"/>';
      };

      var linkGridPanel = new Ext.grid.EditorGridPanel({
        title: "Links",
        columnWidth:1/3,
        height:175,
        store: linkDataStore,
        cm: new Ext.grid.ColumnModel([
            {id: "delete", width: 10, dataIndex: 'id', renderer: editRenderer, sortable: false, menuDisabled: true, hideable: false, tooltip: "Delete row" },
            {id: "name", header: "Name", sortable: true, dataIndex: 'name', editor: #{render_grid_name_combobox}},
            {id: "url", header: "URL", width: 150, sortable: true, dataIndex: 'url', editor: #{render_grid_textfield}}
          ]),
        #{render_contact_route_grid_options},
        selModel: new Ext.grid.RowSelectionModel({
          listeners:
            {
              selectionchange: function(selectionModel){
                records = selectionModel.getSelections();
                var ids = new Array();
                records.each( function(e) {
                  ids.push(e.id);
                });
                selectedLinkIds = ids;
              }
            }
        })
      });

      linkGridPanel.on("cellclick", function(gr, rowIndex, columnIndex, e) {
        var record = gr.getStore().getAt(rowIndex);
        var id = record.data.id;

        switch(columnIndex){
          case gr.getColumnModel().getIndexById("delete"):
            Ext.Msg.confirm("", "Delete link permanently?", function(btn){
              if ( btn.match(new RegExp("yes","i")) ) {
                var params = {};
                params['ids'] = selectedLinkIds.toString();
                Ext.Ajax.request({
                  url: #{destroy_collection_party_links_path(:party_id => @party.id).to_json},
                  params: params,
                  method: "POST",
                  success: function(response, options){
                    gr.getStore().reload();
                  }
                });
              }
            });
            break;
          default:
            break;
        }
      });

      var updateNewLinkPath = #{update_new_party_link_path(:party_id => @party.id, :id => "__ID__").to_json};

      linkGridPanel.on("validateedit", function(event){
        var record = event.record;
        var editedFieldName = event.field;

        record.set(editedFieldName, event.value);
        var method = "put";
        var objectId = record.get("id");

        var params = {};
        params["link[name]"] = record.get("name");
        params["link[url]"] = record.get("url");

        new Ajax.Request(updateNewLinkPath.sub("__ID__", objectId),{
          method: method,
          parameters: params,
          onSuccess: function(transport){
            response = Ext.util.JSON.decode(transport.responseText);
            record.set('id', response.id);
            record.set('name', response.name);
            record.set('url', response.url);
            if(response.flash && response.flash.include("Error:"))
              event.grid.getView().getCell(event.row, event.column).highlight({startcolor: "FF5721"});
            else
              event.grid.getView().getCell(event.row, event.column).highlight();
          }
        });

      });

      var createLinkFormPanel = new Ext.form.FormPanel({
        items: [
          new Ext.form.ComboBox({
            fieldLabel: "Name",
            labelSeparator: ":",
            name: "link[name]",
            store: namesStore,
            displayField: 'value',
            triggerAction: 'all',
            minChars: 0,
            allowBlank: false,
            editable: true,
            mode: 'local'
          }),
          new Ext.form.TextField({
            grow: true,
            growMin: 148,
            fieldLabel: "URL",
            labelSeparator: ":",
            allowBlank: false,
            name: "link[url]",
            value: ""
          })
        ]
      });

      var createLinkWindow = new Ext.Window({
        title: "Create new link",
        items: [createLinkFormPanel],
        height: 120,
        width: 350,
        resizable: false,
        closeAction: 'hide',
        listeners:{hide: function(panel){linkGridPanel.enable();}},
        buttons:[
            {
              text: "Create",
              handler: function() {
                  createLinkFormPanel.getForm().doAction("submit",
                    {
                      url: #{create_new_party_links_path(:party_id => @party.id).to_json},
                      method: "POST",
                      success: function(form, action){
                        linkGridPanel.getStore().reload();
                      },
                      failure: function(form, action){
                        response = action.result
                        Ext.Msg.show({
                          title: "Saving failed",
                          msg: response.messages,
                          buttons: Ext.Msg.OK,
                          minWidth: 750
                        })
                      }
                    }
                  )
                  if(createLinkFormPanel.getForm().isValid()) {
                    linkGridPanel.enable();
                    createLinkWindow.hide();
                  }
                }
            },
            {
              text: 'Cancel',
              handler: function() {
                linkGridPanel.enable();
                createLinkWindow.hide();
              }
            }
          ]
      });
      linkDataStore.load();
    `
  end

  def initialize_phone_grid_panel
    %Q`
      var selectedPhoneIds = null;

      var PhoneRecord = new Ext.data.Record.create([
          {name: 'id', mapping: 'id'},
          {name: 'name', mapping: 'name'},
          {name: 'number', mapping: 'number'},
          {name: 'extension', mapping: 'extension'}
        ]);

      // data reader to parse the json response
      var phoneReader = new Ext.data.JsonReader({totalProperty: "total", root: "collection", id: "id"}, PhoneRecord);

      // set up connection of the data
      var phoneConnection = new Ext.data.Connection({url: #{formatted_party_phones_path(:party_id => @party.id, :format => :json).to_json}, method: 'get'});
      var phoneProxy = new Ext.data.HttpProxy(phoneConnection);

      // set up the data store and then send request to the server
      var phoneDataStore = new Ext.data.Store({
        proxy: phoneProxy,
        reader: phoneReader,
        baseParams: {q: ''},
        listeners:
          {beforeload: function(store, options){phoneGridPanel.disable()},
           load: function(store, records, options){phoneGridPanel.enable()}}
      });

      var editRenderer = function(value, cell, record) {
        return '<div class="icon_delete pointerOnHover"/>';
      };

      var phoneGridPanel = new Ext.grid.EditorGridPanel({
        title: "Phones",
        columnWidth:1/3,
        height:175,
        style:{"padding-left":"5px", "padding-right":"5px"},
        store: phoneDataStore,
        cm: new Ext.grid.ColumnModel([
            {id: "delete", width: 10, dataIndex: 'id', renderer: editRenderer, sortable: false, menuDisabled: true, hideable: false, tooltip: "Delete row" },{id: "name", header: "Name", sortable: true, dataIndex: 'name', editor: #{render_grid_name_combobox}},
            {id: "number", header: "Number", width: 150, sortable: true, dataIndex: 'number', editor: #{render_grid_textfield}},
            {id: "extension", header: "Extension", width: 70, sortable: true, dataIndex: 'extension', editor: #{render_grid_textfield}}
          ]),
        #{render_contact_route_grid_options},
        selModel: new Ext.grid.RowSelectionModel({
          listeners:
            {
              selectionchange: function(selectionModel){
                records = selectionModel.getSelections();
                var ids = new Array();
                records.each( function(e) {
                  ids.push(e.id);
                });
                selectedPhoneIds = ids;
              }
            }
        })
      });

      phoneGridPanel.on("cellclick", function(gr, rowIndex, columnIndex, e) {
        var record = gr.getStore().getAt(rowIndex);
        var id = record.data.id;

        switch(columnIndex){
          case gr.getColumnModel().getIndexById("delete"):
            Ext.Msg.confirm("", "Delete phone permanently?", function(btn){
              if ( btn.match(new RegExp("yes","i")) ) {
                var params = {};
                params['ids'] = selectedPhoneIds.toString();
                Ext.Ajax.request({
                  url: #{destroy_collection_party_phones_path(:party_id => @party.id).to_json},
                  params: params,
                  method: "POST",
                  success: function(response, options){
                    gr.getStore().reload();
                  }
                });
              }
            });
            break;
          default:
            break;
        }
      });

      var updateNewPhonePath = #{update_new_party_phone_path(:party_id => @party.id, :id => "__ID__").to_json};

      phoneGridPanel.on("validateedit", function(event){
        var record = event.record;
        var editedFieldName = event.field;

        record.set(editedFieldName, event.value);
        var method = "put";
        var objectId = record.get("id");

        var params = {};
        params["phone[name]"] = record.get("name");
        params["phone[extension]"] = record.get("extension");
        params["phone[number]"] = record.get("number");

        new Ajax.Request(updateNewPhonePath.sub("__ID__", objectId),{
          method: method,
          parameters: params,
          onSuccess: function(transport){
            response = Ext.util.JSON.decode(transport.responseText);
            record.set('id', response.id);
            record.set('email_address', response.email_address);
            record.set('name', response.name);
            if(response.flash && response.flash.include("Error:"))
              event.grid.getView().getCell(event.row, event.column).highlight({startcolor: "FF5721"});
            else
              event.grid.getView().getCell(event.row, event.column).highlight();
          }
        });

      });

      var createPhoneFormPanel = new Ext.form.FormPanel({
        items: [
          new Ext.form.ComboBox({
            fieldLabel: "Name",
            labelSeparator: ":",
            name: "phone[name]",
            store: phoneNamesStore,
            displayField: 'value',
            triggerAction: 'all',
            minChars: 0,
            allowBlank: false,
            editable: true,
            mode: 'local'
          }),
          new Ext.form.TextField({
            grow: true,
            growMin: 148,
            fieldLabel: "Number",
            labelSeparator: ":",
            allowBlank: false,
            name: "phone[number]",
            value: ""
          }),
          new Ext.form.TextField({
            grow: true,
            growMin: 148,
            fieldLabel: "Extension",
            labelSeparator: ":",
            name: "phone[extension]",
            value: ""
          })
        ]
      });

      var createPhoneWindow = new Ext.Window({
        title: "Create new phone",
        items: [createPhoneFormPanel],
        height: 145,
        width: 350,
        resizable: false,
        closeAction: 'hide',
        listeners:{hide: function(panel){phoneGridPanel.enable();}},
        buttons:[
            {
              text: "Create",
              handler: function() {
                  createPhoneFormPanel.getForm().doAction("submit",
                    {
                      url: #{create_new_party_phones_path(:party_id => @party.id).to_json},
                      method: "POST",
                      success: function(form, action){
                        phoneGridPanel.getStore().reload();
                      },
                      failure: function(form, action){
                        response = action.result
                        Ext.Msg.show({
                          title: "Saving failed",
                          msg: response.messages,
                          buttons: Ext.Msg.OK,
                          minWidth: 750
                        })
                      }
                    }
                  )
                  if(createPhoneFormPanel.getForm().isValid()) {
                    phoneGridPanel.enable();
                    createPhoneWindow.hide();
                  }
                }
            },
            {
              text: 'Cancel',
              handler: function() {
                phoneGridPanel.enable();
                createPhoneWindow.hide();
              }
            }
          ]
      });
      phoneDataStore.load();
    `
  end

  def initialize_email_grid_panel
    %Q`
      var selectedEmailIds = null;

      var EmailRecord = new Ext.data.Record.create([
          {name: 'id', mapping: 'id'},
          {name: 'name', mapping: 'name'},
          {name: 'email_address', mapping: 'email_address'}
        ]);

      // data reader to parse the json response
      var emailReader = new Ext.data.JsonReader({totalProperty: "total", root: "collection", id: "id"}, EmailRecord);

      // set up connection of the data
      var emailConnection = new Ext.data.Connection({url: #{formatted_party_emails_path(:party_id => @party.id, :format => :json).to_json}, method: 'get'});
      var emailProxy = new Ext.data.HttpProxy(emailConnection);

      // set up the data store and then send request to the server
      var emailDataStore = new Ext.data.Store({
        proxy: emailProxy,
        reader: emailReader,
        baseParams: {q: ''},
        listeners:
          {beforeload: function(store, options){emailGridPanel.disable()},
           load: function(store, records, options){emailGridPanel.enable()}}
      });

      var editRenderer = function(value, cell, record) {
        return '<div class="icon_delete pointerOnHover"/>';
      };

      var emailGridPanel = new Ext.grid.EditorGridPanel({
        title: "Emails",
        store: emailDataStore,
        columnWidth:1/3,
        height:175,
        cm: new Ext.grid.ColumnModel([
            {id: "delete", width: 10, dataIndex: 'id', renderer: editRenderer, sortable: false, menuDisabled: true, hideable: false, tooltip: "Delete row" },
            {id: "name", header: "Name", sortable: true, dataIndex: 'name', editor: #{render_grid_name_combobox}},
            {id: "email_address", header: "Email Address", width: 200, sortable: true, dataIndex: 'email_address', editor: #{render_grid_textfield}}
          ]),
        #{render_contact_route_grid_options},
        selModel: new Ext.grid.RowSelectionModel({
          listeners:
            {
              selectionchange: function(selectionModel){
                records = selectionModel.getSelections();
                var ids = new Array();
                records.each( function(e) {
                  ids.push(e.id);
                });
                selectedEmailIds = ids;
              }
            }
        })
      });

      emailGridPanel.on("cellclick", function(gr, rowIndex, columnIndex, e) {
        var record = gr.getStore().getAt(rowIndex);
        var id = record.data.id;

        switch(columnIndex){
          case gr.getColumnModel().getIndexById("delete"):
            Ext.Msg.confirm("", "Delete email permanently?", function(btn){
              if ( btn.match(new RegExp("yes","i")) ) {
                var params = {};
                params['ids'] = selectedEmailIds.toString();
                Ext.Ajax.request({
                  url: #{destroy_collection_party_emails_path(:party_id => @party.id).to_json},
                  params: params,
                  method: "POST",
                  success: function(response, options){
                    gr.getStore().reload();
                  }
                });
              }
            });
            break;
          default:
            break;
        }
      });

      var updateNewEmailPath = #{update_new_party_email_path(:party_id => @party.id, :id => "__ID__").to_json};

      emailGridPanel.on("validateedit", function(event){
        var record = event.record;
        var editedFieldName = event.field;

        record.set(editedFieldName, event.value);
        var method = "put";
        var objectId = record.get("id");

        var params = {};
        params["email[name]"] = record.get("name");
        params["email[email_address]"] = record.get("email_address");

        new Ajax.Request(updateNewEmailPath.sub("__ID__", objectId),{
          method: method,
          parameters: params,
          onSuccess: function(transport){
            response = Ext.util.JSON.decode(transport.responseText);
            record.set('id', response.id);
            record.set('email_address', response.email_address);
            record.set('name', response.name);
            if(response.flash && response.flash.include("Error:"))
              event.grid.getView().getCell(event.row, event.column).highlight({startcolor: "FF5721"});
            else
              event.grid.getView().getCell(event.row, event.column).highlight();
          }
        });

      });

      var createEmailFormPanel = new Ext.form.FormPanel({
        items: [
          new Ext.form.ComboBox({
            fieldLabel: "Name",
            labelSeparator: ":",
            name: "email[name]",
            store: namesStore,
            displayField: 'value',
            triggerAction: 'all',
            minChars: 0,
            allowBlank: false,
            editable: true,
            mode: 'local'
          }),
          new Ext.form.TextField({
            grow: true,
            growMin: 148,
            fieldLabel: "Email Address",
            allowBlank: false,
            labelSeparator: ":",
            name: "email[email_address]",
            value: ""
          })
        ]
      });

      var createEmailWindow = new Ext.Window({
        title: "Create new email",
        items: [createEmailFormPanel],
        height: 120,
        width: 350,
        resizable: false,
        closeAction: 'hide',
        listeners:{hide: function(panel){emailGridPanel.enable();}},
        buttons:[
            {
              text: "Create",
              handler: function() {
                  createEmailFormPanel.getForm().doAction("submit",
                    {
                      url: #{create_new_party_emails_path(:party_id => @party.id).to_json},
                      method: "POST",
                      success: function(form, action){
                        emailGridPanel.getStore().reload();
                      },
                      failure: function(form, action){
                        response = action.result
                        Ext.Msg.show({
                          title: "Saving failed",
                          msg: response.messages,
                          buttons: Ext.Msg.OK,
                          minWidth: 750
                        })
                      }
                    }
                  )
                  if(createEmailFormPanel.getForm().isValid()) {
                    emailGridPanel.enable();
                    createEmailWindow.hide();
                  }
                }
            },
            {
              text: 'Cancel',
              handler: function() {
                emailGridPanel.enable();
                createEmailWindow.hide();
              }
            }
          ]
      });
      emailDataStore.load();
    `
  end

  def initialize_address_grid_panel
    %Q`
      ///////////////////////////////////// ADDRESS GRID //////////////////////////////////////////////////
      var selectedAddressIds = null;

      var AddressRecord = new Ext.data.Record.create([
        {name: 'id', mapping: 'id'},
        {name: 'name', mapping: 'name'},
        {name: 'line1', mapping: 'line1'},
        {name: 'line2', mapping: 'line2'},
        {name: 'line3', mapping: 'line3'},
        {name: 'city', mapping: 'city'},
        {name: 'state', mapping: 'state'},
        {name: 'zip', mapping: 'zip'},
        {name: 'country', mapping: 'country'},
        {name: 'longitude', mapping: 'longitude'},
        {name: 'latitude', mapping: 'latitude'}
      ]);

      // data reader to parse the json response
      var addressReader = new Ext.data.JsonReader({totalProperty: "total", root: "collection", id: "id"}, AddressRecord);

      // set up connection of the data
      var addressConnection = new Ext.data.Connection({url: #{formatted_party_addresses_path(:party_id => @party.id, :format => :json).to_json}, method: 'get'});
      var addressProxy = new Ext.data.HttpProxy(addressConnection);

      // set up the data store and then send request to the server
      var addressDataStore = new Ext.data.Store({
        proxy: addressProxy,
        reader: addressReader,
        baseParams: {q: ''},
        listeners:
          {beforeload: function(store, options){addressGridPanel.disable()},
           load: function(store, records, options){addressGridPanel.enable()}}
      });

      var countriesComboBox = new Ext.form.ComboBox({
        store: countriesStore,
        displayField: 'value',
        valueField: 'id',
        triggerAction: 'all',
        minChars: 0,
        allowBlank: false,
        editable: true,
        mode: 'local',
        selectOnFocus: true
      });

      var statesComboBox = new Ext.form.ComboBox({
        store: statesStore,
        displayField: 'value',
        valueField: 'id',
        triggerAction: 'all',
        minChars: 0,
        allowBlank: false,
        editable: true,
        mode: 'local',
        selectOnFocus: true
      });

      var editRenderer = function(value, cell, record) {
        return '<div class="icon_delete pointerOnHover"/>';
      };

      var addressGridPanel = new Ext.grid.EditorGridPanel({
        title: "Addresses",
        columnWidth:1,
        height:175,
        store: addressDataStore,
        cm: new Ext.grid.ColumnModel([
            {id: "delete", width: 10, dataIndex: 'id', renderer: editRenderer, sortable: false, menuDisabled: true, hideable: false, tooltip: "Delete row" },
            {id: "name", header: "Name", sortable: true, dataIndex: 'name', editor: #{render_grid_name_combobox}},
            {id: "line1", header: "Line 1", sortable: true, dataIndex: 'line1', editor: #{render_grid_textfield}},
            {id: "line2", header: "Line 2", sortable: true, dataIndex: 'line2', editor: #{render_grid_textfield}},
            {id: "line3", header: "Line 3", sortable: true, dataIndex: 'line3', editor: #{render_grid_textfield}},
            {id: "city", header: "City", width: 70, sortable: true, dataIndex: 'city', editor: #{render_grid_textfield}},
            {id: "state", header: "State", width: 70, sortable: true, dataIndex: 'state', editor: statesComboBox},
            {id: "country", header: "Country", width: 70, sortable: true, dataIndex: 'country', editor: countriesComboBox},
            {id: "zip", header: "Postal", width: 70, sortable: true, dataIndex: 'zip', editor: #{render_grid_textfield}},
            {id: "longitude", header: "Longitude", width: 70, sortable: true, dataIndex: 'longitude', hidden: true, editor: #{render_grid_textfield}},
            {id: "latitude", header: "Latitude", width: 70, sortable: true, dataIndex: 'latitude', hidden: true, editor: #{render_grid_textfield}}
          ]),
        #{render_contact_route_grid_options},
        selModel: new Ext.grid.RowSelectionModel({
          listeners:
            {
              selectionchange: function(selectionModel){
                records = selectionModel.getSelections();
                var ids = new Array();
                records.each( function(e) {
                  ids.push(e.id);
                });
                selectedAddressIds = ids;
              }
            }
        })
      });

      addressGridPanel.on("cellclick", function(gr, rowIndex, columnIndex, e) {
        var record = gr.getStore().getAt(rowIndex);
        var id = record.data.id;

        switch(columnIndex){
          case gr.getColumnModel().getIndexById("delete"):
            Ext.Msg.confirm("", "Delete address permanently?", function(btn){
              if ( btn.match(new RegExp("yes","i")) ) {
                var params = {};
                params['ids'] = selectedAddressIds.toString();
                Ext.Ajax.request({
                  url: #{destroy_collection_party_addresses_path(:party_id => @party.id).to_json},
                  params: params,
                  method: "POST",
                  success: function(response, options){
                    gr.getStore().reload();
                  }
                });
              }
            });
            break;
          default:
            break;
        }
      });
      
      var updateNewAddressPath = #{update_new_party_address_path(:party_id => @party.id, :id => "__ID__").to_json};

      addressGridPanel.on("validateedit", function(event){
        var record = event.record;
        var editedFieldName = event.field;

        record.set(editedFieldName, event.value);
        var method = "put";
        var objectId = record.get("id");

        var params = {};
        params["address[name]"] = record.get("name");
        params["address[line1]"] = record.get("line1");
        params["address[line2]"] = record.get("line2");
        params["address[line3]"] = record.get("line3");
        params["address[city]"] = record.get("city");
        params["address[state]"] = record.get("state");
        params["address[zip]"] = record.get("zip");
        params["address[country]"] = record.get("country");
        params["address[latitude]"] = record.get("latitude");
        params["address[longitude]"] = record.get("longitude");

        new Ajax.Request(updateNewAddressPath.sub("__ID__", objectId),{
          method: method,
          parameters: params,
          onSuccess: function(transport){
            response = Ext.util.JSON.decode(transport.responseText);
            record.set('id', response.id);
            record.set('name', response.name);
            record.set('line1', response.line1);
            record.set('line2', response.line2);
            record.set('line3', response.line3);
            record.set('city', response.city);
            record.set('state', response.state);
            record.set('zip', response.zip);
            record.set('country', response.country);
            record.set('longitude', response.longitude);
            record.set('latitude', response.latitude);
            if(response.flash && response.flash.include("Error:"))
              event.grid.getView().getCell(event.row, event.column).highlight({startcolor: "FF5721"});
            else
              event.grid.getView().getCell(event.row, event.column).highlight();
          }
        });

      });

      ///////////////////////////////////// END ADDRESS GRID //////////////////////////////////////////////////


      ////////////////////////////////////////CREATE ADDRESS WINDOW////////////////////////////////////////


      var createAddressFormPanel = new Ext.form.FormPanel({
        items: [
          new Ext.form.ComboBox({
            fieldLabel: "Name",
            labelSeparator: ":",
            name: "address[name]",
            store: namesStore,
            displayField: 'value',
            triggerAction: 'all',
            minChars: 0,
            allowBlank: false,
            editable: true,
            mode: 'local'
          }),
          new Ext.form.TextField({
            grow: true,
            growMin: 148,
            fieldLabel: "Line 1",
            labelSeparator: ":",
            name: "address[line1]",
            value: ""
          }),
          new Ext.form.TextField({
            grow: true,
            growMin: 148,
            fieldLabel: "Line 2",
            labelSeparator: ":",
            name: "address[line2]",
            value: ""
          }),
          new Ext.form.TextField({
            grow: true,
            growMin: 148,
            fieldLabel: "Line 3",
            labelSeparator: ":",
            name: "address[line3]",
            value: ""
          }),
          new Ext.form.TextField({
            grow: true,
            growMin: 148,
            fieldLabel: "City",
            labelSeparator: ":",
            name: "address[city]",
            value: ""
          }),
          new Ext.form.ComboBox({
            fieldLabel: "Prov/State",
            labelSeparator: ":",
            name: "address[state]",
            store: statesStore,
            displayField: 'value',
            valueField: 'id',
            triggerAction: 'all',
            minChars: 0,
            allowBlank: false,
            editable: true,
            mode: 'local'
          }),
          new Ext.form.ComboBox({
            fieldLabel: "Country",
            labelSeparator: ":",
            name: "address[country]",
            store: countriesStore,
            displayField: 'value',
            valueField: 'id',
            triggerAction: 'all',
            minChars: 0,
            allowBlank: false,
            editable: true,
            mode: 'local'
          }),
          new Ext.form.TextField({
            grow: true,
            growMin: 148,
            fieldLabel: "Postal Code",
            labelSeparator: ":",
            name: "address[zip]",
            value: ""
          })
        ]
      });

      var createAddressWindow = new Ext.Window({
        title: "Create new address",
        items: [createAddressFormPanel],
        height: 275,
        width: 350,
        resizable: false,
        closeAction: 'hide',
        listeners:{hide: function(panel){addressGridPanel.enable();}},
        buttons:[
            {
              text: "Create",
              handler: function() {
                  createAddressFormPanel.getForm().doAction("submit",
                    {
                      url: #{create_new_party_addresses_path(:party_id => @party.id).to_json},
                      method: "POST",
                      success: function(form, action){
                        addressGridPanel.getStore().reload();
                      },
                      failure: function(form, action){
                        response = action.result
                        Ext.Msg.show({
                          title: "Saving failed",
                          msg: response.messages,
                          buttons: Ext.Msg.OK,
                          minWidth: 750
                        })
                      }
                    }
                  )
                  if(createAddressFormPanel.getForm().isValid()) {
                    addressGridPanel.enable();
                    createAddressWindow.hide();
                  }
                }
            },
            {
              text: 'Cancel',
              handler: function() {
                addressGridPanel.enable();
                createAddressWindow.hide();
              }
            }
          ]
      });

      ////////////////////////////////////END CREATE ADDRESS WINDOW////////////////////////////////////////

      addressDataStore.load();
    `
  end

  def render_record_modifier
    %Q`
      <div class="party-wrap"><p class="recordStatus">Created by <span class="createdBy_name">#{@party.created_by.name rescue "Unknown"}</span> on <span class="createdBy_date">#{current_user.format_utc_date(@party.created_at || Time.now)}</span>, at <span id="createdBy_timestamp">#{current_user.format_utc_time(@party.created_at || Time.now)}</span>
      &nbsp;&nbsp;&nbsp;&nbsp;Modified by <span class="modifiedBy_name">#{@party.updated_by.name rescue "Unknown"}</span> on <span class="modifiedBy_date">#{current_user.format_utc_date(@party.updated_at || Time.now)}</span>, at <span id="modifiedBy_timestamp">#{current_user.format_utc_time(@party.updated_at || Time.now)}</span>
      &nbsp;&nbsp;&nbsp;&nbsp;Referred by <span class="referredBy_name">#{link_to_function(@party.referred_by.name, "xl.openNewTabPanel('parties_edit_#{@party.referred_by_id}', #{edit_party_path(:id => @party.referred_by_id).to_json})") rescue "Unknown"}</span></p></div>
    `
  end

  def render_tabpanels_javascript

    email_accounts_panel = %Q!autoLoad: {url:'#{party_email_accounts_path(@party)}', scripts:true}!
    network_panel = %Q!autoLoad: {url:'#{network_party_path(@party)}', scripts:true}!
    profile_panel = %Q!autoLoad: {url:'#{profile_party_path(@party)}', scripts:true}!
    security_panel = %Q!autoLoad: {url:'#{security_party_path(@party)}', scripts:true}!
    tags_panel = %Q!autoLoad: {url:'#{tags_party_path(@party)}', scripts:true}!

    included_panels = %w(network tags security)
    selected_panel = 'tags_panel'

    if current_user.id == @party.id || current_user.superuser?
      included_panels << "email_accounts"
    end

    if params[:controller] =~ /\Aparties/i
      case params[:action]
      when /^general$/i
        tags_panel = %Q!contentEl: 'tags-panel-content'!
        selected_panel = "tagsPanel"
      when /^network$/i
        network_panel = %Q!contentEl: 'network-panel-content'!
        selected_panel = "networkPanel"
      when /^profile$/i
        profile_panel = %Q!contentEl: 'profile-panel-content'!
        selected_panel = "profilePanel"
      when /^security$/i
        security_panel = %Q!contentEl: 'security-panel-content'!
        selected_panel = "securityPanel"
      when /^tags$/i
        tags_panel = %Q!contentEl: 'tags-panel-content'!
        selected_panel = "tagsPanel"
      end
    end

    if params[:controller] =~ /\Aemail_accounts/i
      email_accounts_panel = %Q!contentEl: 'email-accounts-panel-content'!
      selected_panel = "emailAccountsPanel"
    end

    included_panels = included_panels.reject {|e| e =~ $1}.map {|e| e.camelize(:lower)}.map {|e| e + "Panel"}.join(", ")
    included_panels.gsub!(/["']/, "")

    javascript_tag(%Q!
      Ext.onReady(function(){
        xl = parent.xl;

        var newAction = new Ext.Action({
          text: 'New',
          iconCls: "display_none",
          handler: function(){
            parent.xl.createTab('#{new_party_path}');
          }
        });

        var deleteAction = new Ext.Action({
          text: 'Delete',
          iconCls: "display_none",
          handler: function(){
            if (confirm('Would you like to permanently delete this record?')) {
              new Ajax.Request('#{party_path(@party)}', {asynchronous:true, evalScripts:true, method:'delete'});
            };
            return false;
          }
        });

        var archiveAction = new Ext.Action({
          text: 'Archive',
          iconCls: "display_none",
          handler: function(){
            if (confirm('Are you sure you want to archive this party?')) {
              new Ajax.Request('#{archive_party_path(@party)}', {asynchronous:true, evalScripts:true, method:'put'});
            };
            return false;
          }
        });

        var addToGroupAction = new Ext.Action({
          text: 'Add to group',
          iconCls: "display_none",
          handler: function() {
            Ext.Msg.buttonText.ok = "Add";
            Ext.Msg.show({
              title: "Add selected contacts to a group",
              msg: '<label>Please select a group: </label>#{e( select_tag("group_id", options_for_select(@groups.map {|g| [g.name, g.id]})) )}',
              buttons: Ext.Msg.OKCANCEL,
              fn: function(btn) {
                if ( btn.match(new RegExp("ok","i")) ) {
                  var groupId = $('group_id').options[$('group_id').selectedIndex].value;
                  new Ajax.Request('#{add_collection_to_group_parties_path}', {method:'post', parameters:{group_id:groupId, ids:'#{@party.id}'} });
                }
              }
            });
          }
        });

        var duplicateAction = new Ext.Action({
          text: 'Duplicate',
          iconCls: "display_none",
          handler: function(){
            parent.xl.createTab('#{new_party_path(:id => @party.id)}');
          }
        });

        var emailAction = new Ext.Action({
          text: 'Email',
          iconCls: "display_none",
          disabled: true
        });

        var printSummaryAction = new Ext.Action({
          text: 'Print Summary',
          iconCls: "display_none",
          disabled: true
        });

        var resetPasswordAction = new Ext.Action({
          text: 'Reset password',
          iconCls: "display_none",
          disabled: true
        });

        var sendFileAction = new Ext.Action({
          text: 'Send a file',
          iconCls: "display_none",
          disabled: true
        });

        var partyMenu = new Ext.menu.Menu({
          items: [newAction, deleteAction, archiveAction, addToGroupAction, duplicateAction, emailAction, printSummaryAction, resetPasswordAction, sendFileAction]
        });

        var networkPanel = new Ext.Panel({
          title: 'Network',
          autoScroll: 'auto',
          #{network_panel}
        });

        var tagsPanel = new Ext.Panel({
          title: 'Tags',
          autoScroll: 'auto',
          #{tags_panel}
        });

        var securityPanel = new Ext.Panel({
          title: 'Security',
          autoScroll: 'auto',
          #{security_panel}
        });

        var emailAccountsPanel = new Ext.Panel({
          title: 'Email Accounts',
          autoScroll: 'auto',
          #{email_accounts_panel}
        });

        var profilePanel = new Ext.Panel({
          title: 'Profile',
          autoScroll: 'auto',
          #{profile_panel}
        });

        xl.partyTabPanel = new Ext.TabPanel({
          region: 'south',
          tabPosition: 'bottom',
          split: true,
          border: false, bodyBoder: false, frame: false,
          style: 'padding: 10px;',  // Push the whole TabPanel in 10px on all sides
          activeTab: 0,
          defaults: { cls: 'border2pxLightGreen', autoHeight: false, height: 250 },
          items: #{"["+included_panels+"]"}
        });

        var partyMainPanel = new Ext.Panel({
          tbar: [{text:"Actions", menu:partyMenu}],
          region: 'center',
          height: 350,
          autoScroll: true,
          border: false, bodyBorder: false, frame: false,
          contentEl: 'party-wrap'
        });

        var viewport = new Ext.Viewport({
          renderTo: 'viewport',
          layout: 'border',

          border: false, bodyBorder: false, frame: false,
          cls: 'IAmAPanelWithBorderLayoutContainer',

          items: [partyMainPanel, xl.partyTabPanel]
        });

        var topToolbar = partyMainPanel.getTopToolbar();
        topToolbar.addElement('show-add-field-container');
        topToolbar.addClass("headerBar");
        #{selected_panel}.show();
        //xl.partyTabPanel.setHeight()
      });
    !)
  end

  def close_destroyed_party_related_tabs
    %Q~
      parent.xl.refreshIframe("/admin/parties");
      parent.xl.closeTabs("/admin/parties/#{@party.id}")
    ~
  end
end
