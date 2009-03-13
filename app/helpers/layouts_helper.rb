#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module LayoutsHelper
  def generate_revision_view_panel(variable_name)
    %Q`
      var revisionViewTitle = new Ext.form.TextField({
        value: #{variable_name}.title,
        readOnly: true,
        fieldLabel: "Title",
        name: 'layout[title]'
      });
      
      var revisionViewContentType = new Ext.form.TextField({
        value: #{variable_name}.content_type,
        readOnly: true,
        fieldLabel: "Content type",
        name: 'layout[content_type]'
      });

      var revisionViewEncoding = new Ext.form.TextField({
        value: #{variable_name}.encoding,
        readOnly: true,
        fieldLabel: "Layout",
        name: 'layout[encoding]'
      });

      var revisionViewBodyEditor = new Ext.form.TextArea({
          hideLabel: true,
          name: 'layout[body]',
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
        name: 'layout[domain_patterns]',
        height: 50,
        width: "50%"
      });
      
      var revisionViewPanel = new Ext.Panel({
        layout: "form",
        items: [
          revisionViewTitle,
          revisionViewContentType,
          revisionViewEncoding,
          {
            html: 'Body:'
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

    var setValueOfRevisionFields = function(newLayoutObject){
      titleField.setValue(newLayoutObject.title);
      contentTypeField.setValue(newLayoutObject.content_type);
      encodingField.setValue(newLayoutObject.encoding);
      bodyEditor.setValue(newLayoutObject.body);
      domainPatternsField.setValue(newLayoutObject.domain_patterns);
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

        revisionsConnection = new Ext.data.Connection({url: #{revisions_layout_path(@layout).to_json}, method: 'get'});
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
              var url = #{revision_layout_path(:id => @layout.id, :version => "__VERSION__").to_json}; 
              url = url.sub("__VERSION__", selectedRevision.get("version"));
              Ext.Ajax.request({
                url: url,
                success: function(response, options){
                  var layoutRevision = Ext.util.JSON.decode(response.responseText);
                  if (revisionViewWindow){
                    revisionViewWindow.close();
                  }
                  
                  #{self.generate_revision_view_panel("layoutRevision")}
                  
                  var applyPatchButton = new Ext.Button({
                    text: "Apply revision",
                    handler: function(button, event){
                      Ext.Msg.confirm("Applying patch", "Please save your work before reverting <b>OTHERWISE IT WILL BE LOST</b>. Are you sure you want to apply <b>REVISION " + layoutRevision.version + "</b>?", function(btn){
                        if ( btn.match(new RegExp("yes","i")) ) {
                          setValueOfRevisionFields(layoutRevision);
                          revisionViewWindow.close();
                          revisionsWindow.hide();
                          Ext.Msg.alert("Version Control", "Patch successfully applied");
                        }
                      });
                    }
                  });

                  revisionViewWindow = new Ext.Window({
                    title: #{@layout.title.to_json} + " (Revision " + layoutRevision.version +")",
                    height: 360,
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
          title: #{"Revision history for: #{@layout.title}".to_json},
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
                    url: #{revision_layout_path(:id => @layout.id, :version => @layout.version).to_json},
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
                    url: #{revision_layout_path(:id => @layout.id, :version => @layout.versions.find(:all, :select => "version", :order => "version ASC").first.version).to_json},
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

  def generate_form_panel
  %Q`
    #{self.generate_revisions_button unless @layout.new_record?}
    
    var cacheControlStore = new Ext.data.SimpleStore({
      fields: ['display', 'value'],
      data: [['Private', 'private'], ['Public', 'public'], ['No Cache', 'no-cache']]
    });
    
    var bodyEditor = new Ext.form.TextArea({
        fieldLabel: 'Body',
        name: 'layout[body]',
        width: '99%',
        height: 500,
        value: #{@layout.body.to_json},
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
    
    var cacheTimeout = xl.widget.FormField({ value: #{@layout.cache_timeout_in_seconds.to_json}, name: 'layout[cache_timeout_in_seconds]', fieldLabel: 'Cache Timeout (seconds)', 
                                             id: #{(typed_dom_id(@layout, :cache_timeout_in_seconds)).to_json}, width: 270, disabled: #{(@layout.cache_control_directive =~ /no-cache/i ? true : false).to_json}});
    
    var cacheControlCombobox = new Ext.form.ComboBox({
      fieldLabel: "Cache Control Directive",
      labelSeparator: ":",
      name: "cache_control",
      hiddenName: "layout[cache_control_directive]",
      store: cacheControlStore,
      displayField: "display",
      valueField: "value",
      editable: false,
      mode: "local",
      value: #{(@layout.cache_control_directive || "public").to_json},
      triggerAction: "all", 
      listeners: {
        'select': function(component, record, index){
          if(record.get('value').match(/no-cache/i))
          {
            cacheTimeout.disable();
          }
          else
            cacheTimeout.enable();
        }
      }
    });
  
    var titleField = xl.widget.FormField({ value: #{@layout.title.to_json}, name: 'layout[title]', fieldLabel: 'Title', id: #{typed_dom_id(@layout, :title).to_json}, width: 270});
    var contentTypeField = xl.widget.FormField({ value: #{@layout.content_type.to_json}, name: 'layout[content_type]', fieldLabel: 'Content Type', id: #{typed_dom_id(@layout, :content_type).to_json}, width: 270});
    var encodingField = xl.widget.FormField({ value: #{@layout.encoding.to_json}, name: 'layout[encoding]', fieldLabel: 'Encoding', id: #{typed_dom_id(@layout, :encoding).to_json}, width: 270});
    var domainPatternsField = xl.widget.FormField({ type: 'textarea', value: #{@layout.domain_patterns.to_json}, name: 'layout[domain_patterns]', fieldLabel: 'Domain Patterns', id: #{typed_dom_id(@layout, :fullslug).to_json}, width: 270});

    var noUpdateCheckbox = new Ext.form.Checkbox({
      checked: #{@layout.no_update.to_json},
      name: "layout[no_update_flag]",
      fieldLabel: "No update",
      inputValue: "1"
    });
        
    var mainPanel = new Ext.Panel({
      width: '100%',
      layout: 'table',
      layoutConfig: {
        columns: 1
      },
      items: [
      {
        html: '<div class="notices" id="#{dom_id(@layout)}_errorMessages"/>'
      },
      {
        html: '<h2 class="page_header">Edit Layout</h2>'
      },
      {
        layout: 'form', 
        labelWidth: 100,
        items: [
          titleField,
          contentTypeField,
          encodingField,
          {
            html: '<br class=clear />'
          }
        ]
      },
      {
        html: 'Body:'
      },
      bodyEditor, 
      {
        layout: 'form', 
        items: [
          domainPatternsField,
          {
            html: '<p class="tip"><a target="_blank" href="#{ApplicationHelper::DOMAIN_PATTERNS_GUIDE_URL}" title="xlsuite wiki : multi-domain management">&uArr;What&rsquo;s this?</a><span class="italic" font-size="10px">(Separate patterns with a comma or a new line)</span></p>'
          },
          noUpdateCheckbox,
          {
            html: '<span class="italic" font-size="10px">Checking the no update checkbox will exclude this layout when performing suite update</span>'
          }
        ]
      },{
        layout: 'column',
        style: 'margin-top:10px',
        title: 'Caching',
        collapsible: true,
        items: [
          {
            layout: 'form',
            style: 'margin-right:10px',
            labelWidth: 180,
            items: [
              cacheControlCombobox
            ]
          },
          {
            layout: 'form',
            labelWidth: 180,
            items: [
              cacheTimeout
            ]
          }
        ]
      },
      {
        html: '<div id="page_edit_auth" style="margin-top:30px">' + #{(authorization_fields_for :layout).to_json} + '</div>'
      }]
    });
  
    var formPanel = new Ext.FormPanel({
      autoScroll: true,
      tbar: [#{"revisionsButton, " unless @layout.new_record?}tbarbbarButtons],
      bbar: tbarbbarButtons,
      items: [mainPanel]
    });
  `
  end
end
