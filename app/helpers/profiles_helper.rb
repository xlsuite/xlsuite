#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module ProfilesHelper
  def initialize_other_fields_panel
    other_fields_items = []
    if @profile.info
      text = ""
      @profile.info.keys.each do |key|
        value = @profile.send(key)
        next unless value.kind_of?(String) || value.nil?
        text = %Q`
          xl.widget.InlineActiveField({ form: updateProfileForm, field: {type: "textarea", width: 500, height: 250, value: #{value.to_json}, name: '#{key}', fieldLabel: '#{key.humanize}', id: #{typed_dom_id(@profile, key).to_json}}})
        `
        other_fields_items << text
      end
    end
    if other_fields_items.empty?
      other_fields_items << %Q`
        {html: "No other field specified for this profile"}
      `
    end
    %Q`
      var otherFieldsPanel = new Ext.form.FormPanel({items: [#{other_fields_items.join(", ")}]})
    `
  end
  
  def initialize_profile_details_panel
    avatar_path = nil
    if @profile.avatar
      avatar_path = download_asset_path(:id => @profile.avatar.id, :size => "mini")
    else
      avatar_path = "/images/Mr-Smith.jpg"
    end
    
    avatar_image_tag = %Q`<img src="#{avatar_path}" id="#{typed_dom_id(@profile, :avatar_img_tag)}"/>`

    %Q`
      #{self.create_countries_and_states_store}

      var updateProfileForm = {url: #{profile_path(@profile).to_json}, object: 'profile'};

      var modifiedByPanel = new Ext.Panel({
        style: "padding-bottom: 3px",
        html: #{self.render_record_modifier.to_json}
      });

      var avatarPanel = new Ext.Panel({
        style: "padding:10px",
        items: {html: "<center>" + #{avatar_image_tag.to_json}},
        tbar: [
          {
            text: "Edit party",
            listeners: {
              click: function(button, event){
                Ext.Ajax.request({
                  url: #{edit_party_path(@profile.party).to_json},
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
                xl.widget.OpenSingleImagePicker(#{typed_dom_id(@profile, :avatar_img_tag).to_json}, #{formatted_image_picker_assets_path(:format => :json).to_json}, "Profile", #{@profile.id}, {
                  setAvatar: true,
                  setRelation: true,
                  windowTitle: "Please select your avatar...",
                  beforeSelect: function(window){
                    window.el.mask("Processing...");
                  },
                  afterSelect: function(selectedRecord, window){
                    var params = {};
                    params["profile[avatar_id]"] = selectedRecord.id;
                    Ext.Ajax.request({
                      url: #{profile_path(@profile).to_json},
                      method: "PUT",
                      params: params,
                      success: function(response, options){
                        window.el.unmask();
                      }
                    });
                    Ext.Ajax.request({
                      url: #{add_views_path.to_json},
                      params: {id: selectedRecord.get("id"), classification: "Image", object_type: "Profile", object_id: #{@profile.id}},
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

      var profileDetailsTopLeftPanel = new Ext.Panel({
        autoHeight: true,
        width: 155,
        items:[avatarPanel]
      });

      #{self.render_tags_panel("profile[tag_list]", @profile, current_account.profiles.tags, {:inline_form => "updateProfileForm"})}

      var honorificsStore = new Ext.data.SimpleStore({
        fields: ['display'],
        data: [["Mr."], ["Mrs."], ["Ms"]]
      });
      
      #{self.create_date_selection_data_stores}
      
      var birthdateDayField = xl.widget.InlineActiveField({
        form: updateProfileForm,
        field:{
          value: #{@profile.birthdate_day.to_s.to_json},
          name: "birthdate_day",
          hiddenName: "profile[birthdate_day]",
          displayField: "display",
          valueField: "value",
          id: #{typed_dom_id(@profile, :birthdate_day).to_json},
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
        form: updateProfileForm,
        field:{
          value: #{@profile.birthdate_month.to_s.to_json},
          name: "birthdate_month",
          hiddenName: "profile[birthdate_month]",
          displayField: "display",
          valueField: "value",
          id: #{typed_dom_id(@profile, :birthdate_month).to_json},
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
        form: updateProfileForm,
        field:{
          value: #{@profile.birthdate_year.to_s.to_json},
          name: "birthdate_year",
          hiddenName: "profile[birthdate_year]",
          displayField: "display",
          valueField: "value",
          id: #{typed_dom_id(@profile, :birthdate_year).to_json},
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

      var profileDetailsMiddlePanel = new Ext.Panel({
        width: 300,
        layout: "form",
        items:[
            xl.widget.InlineActiveField({
              form: updateProfileForm,
              field: {
                value: #{@profile.honorific.to_json},
                name: 'honorific',
                displayField: "display",
                fieldLabel: 'Honorific',
                id: #{typed_dom_id(@profile, :honorific).to_json},
                type: 'combobox',
                store: honorificsStore,
                triggerAction: 'all',
                mode: 'local'
              }
            }),
            xl.widget.InlineActiveField({ form: updateProfileForm, field: {value: #{@profile.first_name.to_json}, name: 'first_name', fieldLabel: 'First Name', id: #{typed_dom_id(@profile, :first_name).to_json}}}),
            xl.widget.InlineActiveField({ form: updateProfileForm, field: {value: #{@profile.middle_name.to_json}, name: 'middle_name', fieldLabel: 'Middle Name', id: #{typed_dom_id(@profile, :middle_name).to_json}}}),
            xl.widget.InlineActiveField({ form: updateProfileForm, field: {value: #{@profile.last_name.to_json}, name: 'last_name', fieldLabel: 'Last Name', id: #{typed_dom_id(@profile, :last_name).to_json}}}),
            xl.widget.InlineActiveField({ form: updateProfileForm, field: {value: #{@profile.company_name.to_json}, name: 'company_name', fieldLabel: 'Company Name', id: #{typed_dom_id(@profile, :company_name).to_json}}}),
            xl.widget.InlineActiveField({ form: updateProfileForm, field: {value: #{@profile.position.to_json}, name: 'position', fieldLabel: 'Position', id: #{typed_dom_id(@profile, :position).to_json}}}),
            xl.widget.InlineActiveField({ form: updateProfileForm, field: {value: #{@profile.alias.to_json}, name: 'alias', fieldLabel: 'Alias', id: #{typed_dom_id(@profile, :alias).to_json}}}),
            xl.widget.InlineActiveField({ form: updateProfileForm, field: {value: #{@profile.custom_url.to_json}, name: 'custom_url', fieldLabel: 'Public Profile URL', id: #{typed_dom_id(@profile, :custom_url).to_json}}}),
            birthdateField
        ]
      });
      
      var profileDetailsTopRightPanel = new Ext.Panel({
        title: "Quick Description",
        collapsible: true,
        style: 'margin-left: 10px',
        width: 250,
        html: #{render(:partial => "main_contact_routes").to_json}
      })

      var profileDetailsTopPanel = new Ext.Panel({
        style: "padding-top: 6px; padding-bottom: 3px",
        layout: "column",
        items:[ profileDetailsTopLeftPanel, profileDetailsMiddlePanel, profileDetailsTopRightPanel]
      });
      
      var profileDetailsPanel = new Ext.Panel({
        items: [profileDetailsTopPanel, modifiedByPanel, tagsPanel]
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
      
      var profileRoutesPanel = new Ext.Panel({
        tbar: [
          {
            text:"Add",
            menu: addRoutesMenu
          }
        ],
        defaults: { style: "padding-bottom: 20px"},
        items:[
          addressGridPanel,
          {
            layout: 'column',
            defaults: {columnWidth: 1/3},
            items: [
              emailGridPanel,
              {
                style:"padding-left:5px; padding-right:5px",
                items:[phoneGridPanel]
              },
              linkGridPanel
            ]
          }
        ]
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
      var linkConnection = new Ext.data.Connection({url: #{formatted_profile_links_path(:profile_id => @profile.id, :format => :json).to_json}, method: 'get'});
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
                  url: #{destroy_collection_profile_links_path(:profile_id => @profile.id).to_json},
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

      var updateNewLinkPath = #{update_new_profile_link_path(:profile_id => @profile.id, :id => "__ID__").to_json};
        
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
                      url: #{create_new_profile_links_path(:profile_id => @profile.id).to_json},
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
      var phoneConnection = new Ext.data.Connection({url: #{formatted_profile_phones_path(:profile_id => @profile.id, :format => :json).to_json}, method: 'get'});
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
        store: phoneDataStore,
        cm: new Ext.grid.ColumnModel([
            {id: "delete", width: 10, dataIndex: 'id', renderer: editRenderer, sortable: false, menuDisabled: true, hideable: false, tooltip: "Delete row" },{id: "name", header: "Name", sortable: true, dataIndex: 'name', editor: #{render_grid_name_combobox}},
            {id: "number", header: "Number", width: 150, sortable: true, dataIndex: 'number', editor: #{render_grid_textfield}},
            {id: "extension", header: "Extension", width: 70, sortable: true, dataIndex: 'extension', editor: #{render_grid_textfield}},
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
                  url: #{destroy_collection_profile_phones_path(:profile_id => @profile.id).to_json},
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

      var updateNewPhonePath = #{update_new_profile_phone_path(:profile_id => @profile.id, :id => "__ID__").to_json};

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
                      url: #{create_new_profile_phones_path(:profile_id => @profile.id).to_json},
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
      var emailConnection = new Ext.data.Connection({url: #{formatted_profile_emails_path(:profile_id => @profile.id, :format => :json).to_json}, method: 'get'});
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
        cm: new Ext.grid.ColumnModel([
            {id: "delete", width: 10, dataIndex: 'id', renderer: editRenderer, sortable: false, menuDisabled: true, hideable: false, tooltip: "Delete row" },
            {id: "name", header: "Name", sortable: true, dataIndex: 'name', editor: #{render_grid_name_combobox}},
            {id: "email_address", header: "Email Address", width: 200, sortable: true, dataIndex: 'email_address', editor: #{render_grid_textfield}},
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
                  url: #{destroy_collection_profile_emails_path(:profile_id => @profile.id).to_json},
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

      var updateNewEmailPath = #{update_new_profile_email_path(:profile_id => @profile.id, :id => "__ID__").to_json};

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
                      url: #{create_new_profile_emails_path(:profile_id => @profile.id).to_json},
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
      var addressConnection = new Ext.data.Connection({url: #{formatted_profile_addresses_path(:profile_id => @profile.id, :format => :json).to_json}, method: 'get'});
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
            {id: "latitude", header: "Latitude", width: 70, sortable: true, dataIndex: 'latitude', hidden: true, editor: #{render_grid_textfield}},
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
                  url: #{destroy_collection_profile_addresses_path(:profile_id => @profile.id).to_json},
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
      
      var updateNewAddressPath = #{update_new_profile_address_path(:profile_id => @profile.id, :id => "__ID__").to_json};

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
                      url: #{create_new_profile_addresses_path(:profile_id => @profile.id).to_json},
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

  def render_contact_route_grid_options
    %Q`
      viewConfig: {
          forceFit: true
      },
      autoScroll: true,
      autoWidth: true,
      autoHeight: true,
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

  def render_record_modifier
    %Q`
      <div class="profile-wrap"><p class="recordStatus">Created on <span class="createdBy_date">#{current_user.format_utc_date(@profile.created_at || Time.now)}</span>, at <span id="createdBy_timestamp">#{current_user.format_utc_time(@profile.created_at || Time.now)}</span>
      &nbsp;&nbsp;&nbsp;&nbsp;Modified on <span class="modifiedBy_date">#{current_user.format_utc_date(@profile.updated_at || Time.now)}</span>, at <span id="modifiedBy_timestamp">#{current_user.format_utc_time(@profile.updated_at || Time.now)}</span></p></div>
    `
  end  
end
