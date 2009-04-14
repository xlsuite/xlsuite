#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module PagesHelper

  def generate_revision_view_panel(variable_name)
    %Q`
      var revisionViewTitle = new Ext.form.TextField({
        value: #{variable_name}.title,
        readOnly: true,
        fieldLabel: "Title",
        name: 'page[title]'
      });
      
      var revisionViewBodyEditor = new Ext.form.TextArea({
          hideLabel: true,
          name: 'page[body]',
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
      
      var revisionViewFullslug = new Ext.form.TextField({
        value: #{variable_name}.fullslug,
        readOnly: true,
        fieldLabel: "Fullslug",
        name: 'page[fullslug]'
      });

      var revisionViewLayout = new Ext.form.TextField({
        value: #{variable_name}.layout,
        readOnly: true,
        fieldLabel: "Layout",
        name: 'page[layout]'
      });

      var revisionViewDomainPatterns = new Ext.form.TextArea({
        value: #{variable_name}.domain_patterns,
        readOnly: true,
        fieldLabel: "Domain Patterns",
        name: 'page[domain_patterns]',
        height: 50,
        width: '90%'
      });

      var revisionViewMetaDescription = new Ext.form.TextArea({
        value: #{variable_name}.meta_description,
        readOnly: true,
        fieldLabel: "Meta Description",
        name: 'page[meta_description]',
        height: 50,
        width: '90%'
      });

      var revisionViewMetaKeywords = new Ext.form.TextArea({
        value: #{variable_name}.meta_keywords,
        readOnly: true,
        fieldLabel: "Meta Keywords",
        name: 'page[meta_keywords]',
        height: 50,
        width: '90%'
      });
      
      var revisionViewPanel = new Ext.Panel({
        layout: "form",
        items: [
          revisionViewTitle, 
          {
            html: 'HTML content:'
          },
          revisionViewBodyEditor,
          {
            layout: "column",
            items: [
              {
                layout: "form",
                columnWidth: .5,
                items: [revisionViewFullslug, revisionViewLayout]
              },
              {
                layout: "form",
                columnWidth: .5,
                items: [revisionViewDomainPatterns]
              }
            ]
          },
          revisionViewMetaDescription,
          revisionViewMetaKeywords
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

    var setValueOfRevisionFields = function(newPageObject){
      titleField.setValue(newPageObject.title);
      bodyEditor.setValue(newPageObject.body);
      fullslugField.setValue(newPageObject.fullslug);
      layoutField.setValue(newPageObject.layout);
      domainPatternsField.setValue(newPageObject.domain_patterns);
      metaDescriptionField.setValue(newPageObject.meta_description);
      metaKeywordsField.setValue(newPageObject.meta_keywords);
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

        revisionsConnection = new Ext.data.Connection({url: #{revisions_page_path(@page).to_json}, method: 'get'});
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
          autoHeight: true,
          listeners: {
            render: function(gp){
              var size = gp.ownerCt.getSize();
              gp.setSize(size.width, size.height);
              revisionsDataStore.load();
            },
            rowdblclick: function(gp, rowIndex, event){
              var selectedRevision = revisionsDataStore.getAt(rowIndex);
              var url = #{revision_page_path(:id => @page.id, :version => "__VERSION__").to_json}; 
              url = url.sub("__VERSION__", selectedRevision.get("version"));
              Ext.Ajax.request({
                url: url,
                success: function(response, options){
                  var pageRevision = Ext.util.JSON.decode(response.responseText);
                  if (revisionViewWindow){
                    revisionViewWindow.close();
                  }
                  
                  #{self.generate_revision_view_panel("pageRevision")}
                  
                  var applyPatchButton = new Ext.Button({
                    text: "Apply revision",
                    handler: function(button, event){
                      Ext.Msg.confirm("Applying patch", "Please save your work before reverting <b>OTHERWISE IT WILL BE LOST</b>. Are you sure you want to apply <b>REVISION " + pageRevision.version + "</b>?", function(btn){
                        if ( btn.match(new RegExp("yes","i")) ) {
                          setValueOfRevisionFields(pageRevision);
                          revisionViewWindow.close();
                          revisionsWindow.hide();
                          Ext.Msg.alert("Version Control", "Patch successfully applied");
                        }
                      });
                    }
                  });

                  revisionViewWindow = new Ext.Window({
                    title: #{@page.title.to_json} + " (Revision " + pageRevision.version +")",
                    height: 412,
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
          title: #{"Revision history for: #{@page.title}".to_json},
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
                    url: #{revision_page_path(:id => @page.id, :version => @page.version).to_json},
                    success: function(response, options){
                      var pageRevision = Ext.util.JSON.decode(response.responseText);
                      setValueOfRevisionFields(pageRevision);
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
                    url: #{revision_page_path(:id => @page.id, :version => @page.versions.find(:all, :select => "version", :order => "version ASC").first.version).to_json},
                    success: function(response, options){
                      var pageRevision = Ext.util.JSON.decode(response.responseText);
                      setValueOfRevisionFields(pageRevision);
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
  @behavior = Item::VALID_BEHAVIORS.include?(@page.behavior) ? @page.behavior : "plain_text"
  
  out = %Q`  

    var layoutsStore = xl.generateSimpleHttpJSONStore({
      fieldNames: ['value','id'],
      url: '#{async_get_selection_layouts_path}',
      autoLoad: false,
      doLoad: false
    });
  
    var statusStore = new Ext.data.SimpleStore({
      fields: ['value'],
      data: #{Page::STATUSES_FOR_SELECT.to_json}
    });
    
    var behaviorsStore = new Ext.data.SimpleStore({
      fields: ['display', 'value'],
      data: #{Item::BEHAVIORS_FOR_SELECT.to_json}
    });
    
    var cacheControlStore = new Ext.data.SimpleStore({
      fields: ['display', 'value'],
      data: [['Private', 'private'], ['Public', 'public'], ['No Cache', 'no-cache']]
    });
  `
  if @behavior =~ /wysiwyg/i
    out << %Q`
      var bodyEditor = new Ext.ux.HtmlEditor({
          fieldLabel: 'Body',
          name: 'page[body]',
          width: '99%',
          height: 500,
          value: #{@page.body.to_json},
          listeners: {
            'resize': function(component){
              var size = component.ownerCt.body.getSize();
              component.suspendEvents();
              component.setSize(size.width-20, 500);
              component.resumeEvents();
            },
            'render': function(component){
              component.getToolbar().insertButton(16, #{html_editor_image_video_embed_button(@page)});
            }
          }
      });
    `
  else
    out << %Q`
      var bodyEditor = new Ext.form.TextArea({
          fieldLabel: 'Body',
          name: 'page[body]',
          width: '99%',
          height: 500,
          value: #{@page.body.to_json},
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
      name: "page[behavior]",
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
    
    var cacheTimeout = xl.widget.FormField({ value: #{@page.cache_timeout_in_seconds.to_json}, name: 'page[cache_timeout_in_seconds]', fieldLabel: 'Cache Timeout (seconds)', 
                                             id: #{(typed_dom_id(@page, :cache_timeout_in_seconds)).to_json}, width: 270, disabled: #{(@page.cache_control_directive =~ /no-cache/i ? true : false).to_json}});
    
    var cacheControlCombobox = new Ext.form.ComboBox({
      fieldLabel: "Cache Control Directive",
      labelSeparator: ":",
      name: "cache_control",
      hiddenName: "page[cache_control_directive]",
      store: cacheControlStore,
      displayField: "display",
      valueField: "value",
      editable: false,
      mode: "local",
      value: #{(@page.cache_control_directive || "public").to_json},
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
  `
  unless @page.new_record?
  out << %Q`
    #{self.generate_revisions_button}
  `
  end
  out << %Q`
    var titleField = xl.widget.FormField({
      value: #{@page.title.to_json},
      name: 'page[title]',
      fieldLabel: 'Title',
      id: #{(typed_dom_id(@page, :title)).to_json},
      width: 270
    });
    
    var fullslugField = xl.widget.FormField({
      value: #{@page.fullslug.to_json},
      name: 'page[fullslug]',
      fieldLabel: 'FullSlug',
      id: #{(typed_dom_id(@page, :fullslug)).to_json},
      width: 270
    });
    
    var layoutField = xl.widget.FormField({ 
      displayField: 'value', 
      valueField: 'value',
      fieldLabel: 'Layout',
      name: 'page[layout]', 
      type: 'combobox', 
      store: layoutsStore, 
      width: 270,
      editable : true,
      triggerAction: 'all',
      mode: 'remote',
      value: #{@page.layout.to_json},
      listeners: {
        'expand': function(me){
          me.store.reload();
        }
      }
    });
    
    var domainPatternsField = xl.widget.FormField({
      type: 'textarea',
      value: #{@page.domain_patterns.to_json},
      name: 'page[domain_patterns]',
      fieldLabel: 'Domain Patterns',
      id: #{(typed_dom_id(@page, :domain_pattern)).to_json},
      width: 270
    });
    
    var metaDescriptionField = xl.widget.FormField({
      type: 'textarea',
      value: #{@page.meta_description.to_json},
      name: 'page[meta_description]',
      fieldLabel: 'Meta Description',
      id: #{(typed_dom_id(@page, :meta_description)).to_json},
      width: 665
    });
    
    var metaKeywordsField = xl.widget.FormField({
      type: 'textarea',
      value: #{@page.meta_keywords.to_json},
      name: 'page[meta_keywords]',
      fieldLabel: 'Meta Keywords',
      id: #{(typed_dom_id(@page, :meta_keywords)).to_json},
      width: 665
    });
    
    var sslRequiredCheckbox = new Ext.form.Checkbox({
      checked:#{@page.require_ssl.to_json},
      name:"page[require_ssl]",
      fieldLabel:"SSL required",
      inputValue:"1"
    });
    
    var noUpdateCheckbox = new Ext.form.Checkbox({
      checked: #{@page.no_update.to_json},
      name: "page[no_update_flag]",
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
        html: '<div class="notices" id="#{dom_id(@page)}_errorMessages"/>'
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
        layout: 'table', 
        defaults: {
        // applied to each contained panel
          bodyStyle:'padding-right:20px'
        },
        layoutConfig: {
          columns: 2
        },
        items: [
        {
          layout: 'form',
          labelWidth: 60,
          items: [
            fullslugField,
            layoutField,
            behaviorCombobox,
            xl.widget.FormField({ 
              displayField: 'value', 
              valueField: 'value',
              fieldLabel: 'Status',
              name: 'page[status]', 
              type: 'combobox', 
              store: statusStore, 
              editable : false,
              triggerAction: 'all',
              mode: 'local',
              value: #{@page.status.to_json}
            }),
            noUpdateCheckbox,
            {
              html: '<span class="italic" font-size="10px">Checking the no update checkbox will exclude this page when performing suite update</span>'
            },
            sslRequiredCheckbox
          ]
        }, 
        {
          layout: 'form', 
          items: [
            domainPatternsField,
            {
              html: '<p class="tip"><a target="_blank" href="#{ApplicationHelper::DOMAIN_PATTERNS_GUIDE_URL}" title="xlsuite wiki : multi-domain management">&uArr;What&rsquo;s this?</a><span class="italic" font-size="10px">(Separate patterns with a comma or a new line)</span></p>'
            }
          ]
        }]
      },
      {
        layout: 'form', 
        labelWidth: 60,
        items: [
          metaDescriptionField,
          metaKeywordsField
        ]
      },
      {
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
        html: '<div id="page_edit_auth" style="margin-top:30px">' + #{(authorization_fields_for :page).to_json} + '</div>'
      }]
    });
  
    var formPanel = new Ext.FormPanel({
      autoScroll: true,
      tbar: [#{"revisionsButton, " unless @page.new_record?}tbarbbarButtons],
      bbar: [#{"revisionsButton, " unless @page.new_record?}tbarbbarButtons],
      items: [mainPanel],
      trackResetOnLoad: true
    });
  `
  end
  
  def page_fullslug_with_slash(page)
    return "/" if page.blank?
    h(page.to_url + "/")
  end

  def render_best_children_of(page, domain)
    matches = best_matches_for(domain, page.children)
    matches.blank? ? nil : render(:partial => matches)
  end

  def best_matches_for(domain, pages)
    return pages if domain.blank?
    pages.group_by(&:fullslug).values.map do |ps|
      ps.best_match_for_domain(domain)
    end
  end

  def view_link_on(page)
    source_domains = @domain ? [@domain] : account_domains
    domains = source_domains.select {|domain| page.matches_domain?(domain)}
    case domains.size
    when 0
      return nil
    when 1
      url = "http"
      url += "s" if request.ssl?
      url += "://"
      url += domains.first.name
      url += $1 if request.env["HTTP_HOST"] =~ /(:\d+)$/
      url += page.to_url
      link_to("View", url, :icon => "page", :target => "_blank")
    else
      select_tag(typed_dom_id(page, :domain), "<option>View on domain...</option>\n" + options_from_collection_for_select(domains, :name, :name), :class => "viewer")
    end
  end
end
