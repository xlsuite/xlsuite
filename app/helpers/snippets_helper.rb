#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module SnippetsHelper
  def generate_revision_view_panel(variable_name)
    %Q`
      var revisionViewTitle = new Ext.form.TextField({
        value: #{variable_name}.title,
        readOnly: true,
        fieldLabel: "Title",
        name: 'snippet[title]'
      });
      
      var revisionViewBodyEditor = new Ext.form.TextArea({
          hideLabel: true,
          name: 'snippet[body]',
          width: '99%',
          height: 150,
          value: #{variable_name}.body,
          readOnly: true,
          listeners: {
            resize: function(component){
              var size = component.ownerCt.body.getSize();
              component.suspendEvents();
              component.setSize(size.width-20, 150);
              component.resumeEvents();
            }
          }
      });
      
      var revisionViewDomainPatterns = new Ext.form.TextArea({
        value: #{variable_name}.domain_patterns,
        readOnly: true,
        fieldLabel: "Domain Patterns",
        name: 'snippet[domain_patterns]',
        height: 50,
        width: "50%"
      });
      
      var revisionViewPanel = new Ext.Panel({
        layout: "form",
        items: [
          revisionViewTitle,
          {
            html: 'HTML Content:'
          },
          revisionViewBodyEditor,
          revisionViewDomainPatterns
        ]
      });      
    `
  end
  
  def generate_revisions_button
  %Q`
    var revisionsWindow;
    var RevisionRecord;
    var revisionsReader;
    var revisionsConnection;
    var revisionsProxy;
    var revisionsDataStore;
    var revisionsGridPanel;
    
    var revisionViewWindow;

    var setValueOfRevisionFields = function(newSnippetObject){
      titleField.setValue(newSnippetObject.title);
      bodyEditor.setValue(newSnippetObject.body);
      domainPatternsField.setValue(newSnippetObject.domain_patterns);
    };
    
    var showRevisionsAction = function(button, event){
      if (!revisionsWindow){
        RevisionRecord = new Ext.data.Record.create([
          {name: 'id', mapping: 'id'},
          {name: 'created_at', mapping: 'created_at'},
          {name: 'updator', mapping: 'updator'},
          {name: 'version', mapping: 'version'}
        ]);

        revisionsReader = new Ext.data.JsonReader({totalProperty: "total", root: "collection", id: "id"}, RevisionRecord);

        revisionsConnection = new Ext.data.Connection({url: #{revisions_snippet_path(@snippet).to_json}, method: 'get'});
        revisionsProxy = new Ext.data.HttpProxy(revisionsConnection);

        revisionsDataStore = new Ext.data.Store({
          proxy: revisionsProxy,
          reader: revisionsReader,
          remoteSort: false
        });
        
        revisionsGridPanel = new Ext.grid.GridPanel({
          store: revisionsDataStore,
          cm: new Ext.grid.ColumnModel([
            {id:"revision", header: "Revision", sortable: true, dataIndex: 'version'},
            {header: "Created at", width: 200, sortable: true, dataIndex: 'created_at'},
            {header: "Updated by", width: 125, sortable: true, dataIndex: 'updator'}         
          ]),
          autoWidth: true,
          loadMask: true,
          autoExpandColumn: "revision",
          viewConfig: {forceFit: true},
          listeners: {
            render: function(gp){
              var size = gp.ownerCt.getSize();
              gp.setSize(size.width, size.height);
              revisionsDataStore.load();
            },
            rowdblclick: function(gp, rowIndex, event){
              var selectedRevision = revisionsDataStore.getAt(rowIndex);
              var url = #{revision_snippet_path(:id => @snippet.id, :version => "__VERSION__").to_json}; 
              url = url.sub("__VERSION__", selectedRevision.get("version"));
              Ext.Ajax.request({
                url: url,
                success: function(response, options){
                  var snippetRevision = Ext.util.JSON.decode(response.responseText);
                  if (revisionViewWindow){
                    revisionViewWindow.close();
                  }
                  
                  #{self.generate_revision_view_panel("snippetRevision")}
                  
                  var applyPatchButton = new Ext.Button({
                    text: "Apply revision",
                    handler: function(button, event){
                      Ext.Msg.confirm("Applying patch", "Please save your work before reverting <b>OTHERWISE IT WILL BE LOST</b>. Are you sure you want to apply <b>REVISION " + snippetRevision.version + "</b>?", function(btn){
                        if ( btn.match(new RegExp("yes","i")) ) {
                          setValueOfRevisionFields(snippetRevision);
                          revisionViewWindow.close();
                          revisionsWindow.hide();
                          Ext.Msg.alert("Version Control", "Patch successfully applied");
                        }
                      });
                    }
                  });

                  revisionViewWindow = new Ext.Window({
                    title: #{@snippet.title.to_json} + " (Revision " + snippetRevision.version +")",
                    height: 305,
                    width: 600,
                    autoScroll: true,
                    items: [revisionViewPanel],
                    tbar: [applyPatchButton]
                  });
                  revisionViewWindow.show();
                }
              });
            }
          }
        });
        
        revisionsWindow = new Ext.Window({
          title: #{"Revision history for: #{@snippet.title}".to_json},
          height: 300,
          width: 370,
          closeAction: "hide",
          items: revisionsGridPanel,
          listeners: {
            resize: function(win, newWidth, newHeight){
              revisionsGridPanel.setSize(newWidth, newHeight);
            }
          }
        });
      }
      revisionsWindow.show(button);
      revisionsDataStore.reload();
    };
    
    var revisionsButton = new Ext.SplitButton({
      text: "Revision(s)",
      handler: showRevisionsAction,
      menu: new Ext.menu.Menu({
        items: [
          {
            text: "Show revision(s)",
            handler: showRevisionsAction
          },      
          {
            text: "Revert to latest",
            handler: function(button, event){
              Ext.Msg.confirm("Reverting to <b>LATEST</b>", "ALL <b>UNSAVED</b> CHANGES WILL BE LOST. Do you want to proceed?", function(btn){
                if ( btn.match(new RegExp("yes","i")) ) {
                  Ext.Ajax.request({
                    url: #{revision_snippet_path(:id => @snippet.id, :version => @snippet.version).to_json},
                    success: function(response, options){
                      setValueOfRevisionFields(Ext.util.JSON.decode(response.responseText));
                      Ext.Msg.alert("Version Control", "Reverted to the <b>LATEST</b> version");
                    }
                  })
                }
              });
            }
          },
          {
            text: "Revert to oldest",
            handler: function(button, event){
              Ext.Msg.confirm("Reverting to <b>OLDEST</b>", "ALL <b>UNSAVED</b> CHANGES WILL BE LOST. Do you want to revert to the oldest version of the document?", function(btn){
                if ( btn.match(new RegExp("yes","i")) ) {
                  Ext.Ajax.request({
                    url: #{revision_snippet_path(:id => @snippet.id, :version => @snippet.versions.find(:all, :select => "version", :order => "version ASC").first.version).to_json},
                    success: function(response, options){
                      setValueOfRevisionFields(Ext.util.JSON.decode(response.responseText));
                      Ext.Msg.alert("Version Control", "Reverted to the <b>OLDEST</b> version");
                    }
                  })
                }
              });
            }
          }
        ]
      })
    });
  `
  end

  def generate_save_close_cancel_toolbar(object, url, close_url, input_options={})
    raise SyntaxError, "Need to specify options[:page_to_open_after_new] since object is a new record" if object.new_record? && !input_options[:page_to_open_after_new]
    http_method = object.new_record? ? "post" : "put"
    options = input_options.reverse_merge(:method => http_method, :maskPanel => "formPanel")
    
    refresh_other_stores = options[:refresh_other_stores].split(",").map(&:strip).reject(&:blank?).collect do |store|
      refresh_grid_datastore_of("#{store}")
    end if options[:refresh_other_stores]
    
    render_cancel_close_tabs = if options[:page_to_open_after_new]
                  %Q`
                    xl.closeTabs('#{params[:controller]}_new_nil');
                  `
                else
                  %Q`  
                        xl.closeTabPanel(#{self.create_id_from_params.to_json})
                  `
                end
    
    maskPanel = options[:maskPanel]
    out = %Q`
      var successFunction = function(form, action) {
                  xl.log('SUCCESS: ' + action.result);
                  response = action.result;
                  
                  // clear dirty flag on fields
                  form.setValues(form.getValues());
                  if(typeof(response)=="undefined")
                  {
                    #{maskPanel}.el.unmask();
                    xl.maskedPanels.remove(#{maskPanel});
                    Ext.Msg.alert("Saving failed", "Proper connection with the server cannot be established");
                  }  
                  xl.updateStatusBar(response.flash);
                  #{refresh_grid_datastore_of(object.class.name.underscore)}
                  #{refresh_other_stores.join('\n') if refresh_other_stores}
    ` 
    if options[:page_to_open_after_new]
      out << %Q`
                  xl.openNewTabPanel('#{params[:controller]}_edit_'+response.id, #{options[:page_to_open_after_new].to_json}.sub('__ID__', response.id));
                  xl.closeTabs('#{params[:controller]}_new_nil');
      `
    else
      out << %Q`  
                  $("#{dom_id(object)}_errorMessages").innerHTML = "";
                  if(response.close)
                    xl.closeTabs('#{params[:controller]}_edit_'+response.id);
      `
    end
    out << %Q`
                  #{maskPanel}.el.unmask();
                  xl.maskedPanels.remove(#{maskPanel});
      };
      
      var closeSuccessFunction = function(form, action) {
                  response = action.result;
                  
                  // clear dirty flag on fields
                  form.setValues(form.getValues());
                  
                  if(typeof(response)=="undefined")
                  {
                    #{maskPanel}.el.unmask();
                    xl.maskedPanels.remove(#{maskPanel});
                    Ext.Msg.alert("Saving failed", "Proper connection with the server cannot be established");
                  }  
                  $("status-bar-notifications").innerHTML = response.flash; 
                  #{refresh_grid_datastore_of(object.class.name.underscore)}
                  #{refresh_other_stores.join('\n') if refresh_other_stores}
    `
    if options[:page_to_open_after_new]
      out << %Q`
                      xl.closeTabs('#{params[:controller]}_new_nil');
      `
    else
      out << %Q`  
                      if(response.close)
                        xl.closeTabs('#{params[:controller]}_edit_'+response.id);
      `
    end
    out << %Q`
                  #{maskPanel}.el.unmask();
                  xl.maskedPanels.remove(#{maskPanel});
     };
    
      var tbarbbarButtons = [{
        text: 'Save',
        handler: function(me, event){
            #{maskPanel}.el.mask('Saving...');
            xl.maskedPanels.push(#{maskPanel});
            formPanel.getForm().doAction('submit',
              {
                url: #{url.to_json}, 
                method: '#{options[:method]}', 
                success: successFunction,
                failure: function(form, action) {
                  response = action.result;
                  #{maskPanel}.el.unmask();
                  if(response.recursive){
                    Ext.Msg.show({
                      title: "Are you sure?",
                      msg: "This snippet contains a reference to itself. Are you sure you want to save?",
                      buttons: Ext.Msg.YESNO,
                      fn: function(buttonId){
                        if(buttonId == "yes"){
                          #{maskPanel}.el.mask('Saving...');
                          xl.maskedPanels.push(#{maskPanel});
                          formPanel.getForm().doAction('submit',
                          {
                            url: #{url.to_json}, 
                            method: '#{options[:method]}',
                            params: {ignore_warnings: true},
                            success: successFunction,
                            failure: function(form, action) {
                              response = action.result;
                              #{maskPanel}.el.unmask();
                              xl.maskedPanels.remove(#{maskPanel});
                              $("#{dom_id(object)}_errorMessages").innerHTML = response.errors;
                            }
                          });
                        }
                      }
                    });
                  }
                  xl.maskedPanels.remove(#{maskPanel});
                  $("#{dom_id(object)}_errorMessages").innerHTML = response.errors;
                }
              });
          }
      },{
        text: 'Save and Close',
        handler: function(me, event){
            #{maskPanel}.el.mask('Saving...');
            xl.maskedPanels.push(#{maskPanel});
            formPanel.getForm().doAction('submit',
              {
                url: #{close_url.to_json}, 
                method: '#{options[:method]}', 
                success: closeSuccessFunction,
                failure: function(form, action) {
                  xl.logXHRFailure;
                  response = action.result;if(response.recursive){
                    Ext.Msg.show({
                      title: "Are you sure?",
                      msg: "This snippet contains a reference to itself. Are you sure you want to save?",
                      buttons: Ext.Msg.YESNO,
                      fn: function(buttonId){
                        if(buttonId == "yes"){
                          #{maskPanel}.el.mask('Saving...');
                          xl.maskedPanels.push(#{maskPanel});
                          formPanel.getForm().doAction('submit',
                          {
                            url: #{close_url.to_json}, 
                            method: '#{options[:method]}',
                            params: {ignore_warnings: true},
                            success: closeSuccessFunction,
                            failure: function(form, action) {
                              response = action.result;
                              #{maskPanel}.el.unmask();
                              xl.maskedPanels.remove(#{maskPanel});
                              $("#{dom_id(object)}_errorMessages").innerHTML = response.errors;
                            }
                          });
                        }
                      }
                    });
                  }
                  $("#{dom_id(object)}_errorMessages").innerHTML = response.errors;
                  #{maskPanel}.el.unmask();
                  xl.maskedPanels.remove(#{maskPanel});
                }
              });
          }
      },{
        text: "Cancel",
        handler: function(me, event){
          var close = true;
          if(formPanel.getForm().isDirty()){
            Ext.Msg.show({buttons: Ext.Msg.YESNO, title: "Are you sure?", msg: "There are unsaved fields, are you sure you want to close this tab?", fn: function(btn, text){
              if(btn=="no"){
                close = false;
              }
              else{
                #{render_cancel_close_tabs}
              }
            }})
          }
          else{
            #{render_cancel_close_tabs}
          }
        }
      }];
  `
  end
  
  def generate_form_panel
    
  @behavior = Item::VALID_BEHAVIORS.include?(@snippet.behavior) ? @snippet.behavior : "plain_text"
  
  out = %Q`
    #{self.generate_revisions_button unless @snippet.new_record?}
        
    var behaviorsStore = new Ext.data.SimpleStore({
      fields: ['display', 'value'],
      data: #{Item::BEHAVIORS_FOR_SELECT.to_json}
    });
  `
  if @behavior =~ /wysiwyg/i
    out << %Q`
      var bodyEditor = new Ext.ux.HtmlEditor({
          fieldLabel: 'Body',
          name: 'snippet[body]',
          width: '99%',
          height: 500,
          value: #{@snippet.body.to_json},
          listeners: {
            'resize': function(component){
              var size = component.ownerCt.body.getSize();
              component.suspendEvents();
              component.setSize(size.width-20, 500);
              component.resumeEvents();
            },
            'render': function(component){
              component.getToolbar().insertButton(16, #{html_editor_image_video_embed_button(@snippet)});
            }
          }
      });
    `
  else
    out << %Q`
      var bodyEditor = new Ext.form.TextArea({
          fieldLabel: 'Body',
          name: 'snippet[body]',
          width: '99%',
          height: 500,
          value: #{@snippet.body.to_json},
          listeners: {
            'resize': function(component){
              var size = component.ownerCt.body.getSize();
              component.suspendEvents();
              component.setSize(size.width-20, 500);
              component.resumeEvents();
            }
          }, 
          style: "font-family:monospace"
      });
    `
  end
  
  out << %Q`
    var behaviorCombobox = new Ext.form.ComboBox({
      fieldLabel: "Behavior",
      labelSeparator: ":",
      name: "snippet[behavior]",
      store: behaviorsStore,
      displayField: "value",
      editable: false,
      mode: "local",
      value: #{@behavior.to_json},
      triggerAction: "all", 
      listeners: {
        'select': function(component, record, index){
          if(record.get('value').match(/wysiwyg/i))
          {
            Ext.Msg.alert("Are you sure?", "Doing this may cause liquid tags, &lt;!DocType...&gt;, &lt;head&gt;, and &lt;body&gt; tags to not render properly.")
          }  
        }
      }
    });      
      
    var publishedDateField = new Ext.form.DateField({
      fieldLabel: "Publish on",
      name: "snippet[published_at]",
      format: 'F j, Y',
      width: 155,
      allowBlank: true,
      value: #{(@snippet.published_at ? @snippet.published_at.strftime("%Y-%m-%d") : Date.today.to_s).to_json}
    });
    
    var publishedHourField = new Ext.form.ComboBox({
      fieldLabel: 'at',
      labelSeparator: '',
      name: 'published_at[hour]',
      allowBlank: true,
      width: 55,
      store: xl.generateMemoryArrayStore({
        records: xl.generateIdStringRecordsForRange($R(0, 11)),
        idPos: 0,
        mappings: [{name: 'text', mapping: 1}],
        doLoad: true
      }),
      mode: 'local',
      value: #{(@snippet.published_at ? @snippet.published_at.strftime("%I").to_i%12 : "0").to_json},
      displayField: 'text',
      editable: true,
      valueField: 'text',
      triggerAction: 'all'
    });
    
    var publishedMinuteField = new Ext.form.ComboBox({
      fieldLabel: ':',
      labelSeparator: '',
      name: 'published_at[min]',
      allowBlank: true,
      width: 55,
      store: xl.generateMemoryArrayStore({
        records: xl.generateIdStringRecordsForRange($R(0, 55), 5, {pad: 2}),
        idPos: 0,
        mappings: [{name: 'text', mapping: 1}],
        doLoad: true
      }),
      mode: 'local',
      value: #{(@snippet.published_at ? @snippet.published_at.strftime("%M") : "00").to_json},
      displayField: 'text',
      editable: true,
      valueField: 'text',
      triggerAction: 'all'
    });
    
    var publishedAMPMField = new Ext.form.ComboBox({
      labelSeparator: '',
      name: 'published_at[ampm]',
      allowBlank: true,
      width: 45,
      store: xl.generateMemoryArrayStore({
        records: [ [0, 'AM'], [1, 'PM'] ],
        idPos: 0,
        mappings: [{name: 'text', mapping: 1}],
        doLoad: true
      }),
      mode: 'local',
      value: #{(@snippet.published_at ? @snippet.published_at.strftime("%p") : "AM").to_json},
      selectOnFocus: true,
      displayField: 'text',
      editable: false,
      hideLabel: true,
      valueField: 'text',
      triggerAction: 'all'
    });
    
    var titleField = xl.widget.FormField({ value: #{@snippet.title.to_json}, name: 'snippet[title]', fieldLabel: 'Title', id: #{(typed_dom_id(@snippet, :title)).to_json}, width: 270});
    var domainPatternsField = xl.widget.FormField({ type: 'textarea', value: #{@snippet.domain_patterns.to_json}, name: 'snippet[domain_patterns]', fieldLabel: 'Domain Patterns', id: #{(typed_dom_id(@snippet, :fullslug)).to_json}, width: 270});

    var noUpdateCheckbox = new Ext.form.Checkbox({
      checked: #{@snippet.no_update.to_json},
      name: "snippet[no_update_flag]",
      fieldLabel: "No update",
      inputValue: "1"
    });
    
    var mainPanel = new Ext.Panel({
      width: '100%',
      autoScroll: true,
      layout: 'table',
      layoutConfig: {
        columns: 1
      },
      items: [
      {
        html: '<div class="notices" id="#{dom_id(@snippet)}_errorMessages"/>'
      },
      {
        html: '<h2 class="page_header">Edit Snippet</h2>'
      },
      {
        layout: 'form', 
        labelWidth: 60,
        items: [
          titleField,
          {
            html: '<br class=clear />'
          }
        ]
      },
      {
        html: 'Plain Text or HTML content:'
      },
      bodyEditor, 
      {
        layout: 'form', 
        items: [
          behaviorCombobox, 
          { // TableLayout
            layout: 'column',
            defaults: {
              layout: 'form',
              labelWidth: 65,
              labelAlign: 'right'
            },
            items: [
              { // Column 1
                width: 260,
                labelWidth: 100,
                labelAlign: 'left',
                items: [publishedDateField]
              },{ // Column 2
                width: 83,
                labelWidth: 20,
                items: [publishedHourField]
              },{ // Column 3
                width: 70,
                labelWidth: 5,
                items: [publishedMinuteField]
              },{ // Column 4
                width: 55,
                items: [publishedAMPMField]
              },{ // end Column 5
                html: "UTC"
              }
            ] // end ColumnLayout.items
          },
          domainPatternsField,
          {
            html: '<p class="tip"><a target="_blank" href="#{ApplicationHelper::DOMAIN_PATTERNS_GUIDE_URL}" title="xlsuite wiki : multi-domain management">&uArr;What&rsquo;s this?</a><span class="italic" font-size="10px">(Separate patterns with a comma or a new line)</span></p>'
          },
          noUpdateCheckbox,
          {
            html: '<span class="italic" font-size="10px">Checking the no update checkbox will exclude this snippet when performing suite update</span>'
          }
        ]
      },
      {
        html: '<div id="page_edit_auth" style="margin-top:30px">' + #{(authorization_fields_for :snippet).to_json} + '</div>'
      }]
    });
  
    var formPanel = new Ext.FormPanel({
      autoScroll: true,
      autoWidth: true,
      tbar: [#{"revisionsButton, " unless @snippet.new_record?}tbarbbarButtons],
      bbar: tbarbbarButtons,
      items: [mainPanel]
    });
    
  `
  end
end
