#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module AccountTemplatesHelper
  def generate_form_buttons  
    form_url = nil 
    form_method = nil
    confirm_button_label = nil
    extra_button = nil
    extra_code = nil
    close_after_publish = nil
    if @account_template.new_record?
      form_url = account_templates_path
      form_method = "post"
      confirm_button_label = "Publish Template"
      close_after_publish = %Q`
        xl.closeTabPanel("account_templates_new_nil");
        xl.openNewTabPanel('account_templates_new_nil', #{new_account_template_path.to_json});
      `
    else
      confirm_button_label = "Save"
      form_url = account_template_path(@account_template)
      form_method = "put"
      success_message = "Your request has been sent to our system. Please log out now and do not make any change before the update process is finished. You will receive a notification email at #{self.current_user.main_email.email_address} once the update process is completed."
      extra_code = %Q`
        var pushWindow;
        
        var pushPagesCheckboxField = new Ext.form.Checkbox({
          checked: true,
          name: "push[pages]",
          fieldLabel: "Pages"
        });

        var pushSnippetsCheckboxField = new Ext.form.Checkbox({
          checked: true,
          name: "push[snippets]",
          fieldLabel: "Snippets"
        });

        var pushLayoutsCheckboxField = new Ext.form.Checkbox({
          checked: true,
          name: "push[layouts]",
          fieldLabel: "Layouts"
        });

        var pushGroupsCheckboxField = new Ext.form.Checkbox({
          checked: true,
          name: "push[groups]",
          fieldLabel: "Groups"
        });

        var pushAssetsCheckboxField = new Ext.form.Checkbox({
          checked: true,
          name: "push[assets]",
          fieldLabel: "Assets"
        });

        var pushProductsCheckboxField = new Ext.form.Checkbox({
          checked: true,
          name: "push[products]",
          fieldLabel: "Products"
        });

        var pushContactsCheckboxField = new Ext.form.Checkbox({
          checked: true,
          name: "push[contacts]",
          fieldLabel: "Contacts"
        });

        var pushBlogsCheckboxField = new Ext.form.Checkbox({
          checked: true,
          name: "push[blogs]",
          fieldLabel: "Blogs"
        });

        var pushWorkflowsCheckboxField = new Ext.form.Checkbox({
          checked: true,
          name: "push[workflows]",
          fieldLabel: "Workflows"
        });

        var pushFeedsCheckboxField = new Ext.form.Checkbox({
          checked: true,
          name: "push[feeds]",
          fieldLabel: "Feeds"
        });

        var pushEmailTemplatesCheckboxField = new Ext.form.Checkbox({
          checked: true,
          name: "push[email_templates]",
          fieldLabel: "Email Templates"
        });

        var pushLinksCheckboxField = new Ext.form.Checkbox({
          checked: true,
          name: "push[links]",
          fieldLabel: "Links"
        });
        
        var pushFormPanel = new Ext.form.FormPanel({
          items: [
            pushPagesCheckboxField,
            pushSnippetsCheckboxField,
            pushLayoutsCheckboxField,
            pushGroupsCheckboxField,
            pushAssetsCheckboxField,
            pushProductsCheckboxField,
            pushContactsCheckboxField,
            pushBlogsCheckboxField,
            pushWorkflowsCheckboxField,
            pushFeedsCheckboxField,
            pushEmailTemplatesCheckboxField,
            pushLinksCheckboxField
          ]
        });
        
      `
      extra_button = %Q`
          ,
          {
            text: "Push to stable",
            handler: function(me, event){
              if (pushWindow){
                pushWindow.show();
              }
              else{
                pushWindow = new Ext.Window({
                  title: "Push to stable",
                  height: 350,
                  width: 300,
                  resizable: false,
                  items: pushFormPanel,
                  closeAction: "hide",
                  listeners: {
                    resize: function(win, newWidth, newHeight){
                      pushFormPanel.setSize(newWidth, newHeight);
                    }
                  },
                  bbar: new Ext.Button({
                      text: "Push",
                      handler: function(button, event){
                        Ext.Msg.confirm("Updating stable branch", "Do you want to proceed?", function(btn){
                          if ( btn.match(new RegExp("yes","i")) ) {              
                            pushFormPanel.getForm().doAction('submit',
                              {
                                url: #{push_account_template_path(@account_template).to_json},
                                method: "post",
                                success: function(response, options){
                                  Ext.Msg.alert("Template Engine", #{success_message.to_json});
                                  formPanel.el.unmask();
                                },
                                failure: function(response, options){
                                  Ext.Msg.alert("Template Engine", "Sending request failed. Please try again in 5 minutes and contact our admin if the problem persists.");
                                  formPanel.el.unmask();                    
                                }
                              }
                            );
                            formPanel.el.mask("Requesting to push to the stable branch...");
                          }
                        })
                      }
                    })
                });
                pushWindow.show();
              }
            }
          },
          {
            text: "Unpublish",
            handler: function(btn, event){
              Ext.Msg.confirm("Template Engine | Unpublish", "Do you want to proceed?", function(btn){
                if ( btn.match(new RegExp("yes","i")) ) {              
                  Ext.Ajax.request(
                    {
                      url: #{account_template_path(@account_template).to_json},
                      method: "delete",
                      success: function(response, options){
                        var response = Ext.util.JSON.decode(response.responseText);
                        xl.closeTabPanel("account_templates_new_nil");
                        Ext.Msg.alert("Template Engine", response.flash);
                        xl.updateStatusBar(response.flash);
                      },
                      failure: function(response, options){
                        Ext.Msg.alert("Template Engine", "Sending request failed. Please try again in 5 minutes and contact our admin if the problem persists.");
                        formPanel.el.unmask();                    
                      }
                    }
                  );
                  formPanel.el.mask("Requesting to unpublish template...");
                }
              });            
            }
          }
        `
    end
    %Q`
      #{extra_code}
      var globalParameters = {};
      
      var formButtons = [
        {
          text: #{confirm_button_label.to_json},
          handler: function(me, event){
              if (formPanel.getForm().isValid()){
                formPanel.getForm().doAction('submit',
                  {
                    url: #{form_url.to_json},
                    params: globalParameters,
                    method: #{form_method.to_json},
                    success: function(form, action){
                      var response = Ext.util.JSON.decode(action.response.responseText);
                      var errorPanel = Ext.get(#{(dom_id(@account_template) + "_errorMessages").to_json});
                      errorPanel.update("");
                      xl.updateStatusBar(response.flash);
                      formPanel.el.unmask();
                      #{close_after_publish}
                    },
                    failure: function(form, action){
                      var response = Ext.util.JSON.decode(action.response.responseText);
                      var errorPanel = Ext.get(#{(dom_id(@account_template) + "_errorMessages").to_json});
                      errorPanel.update(response.errors);
                      formPanel.el.unmask();
                    }
                  }
                );
                formPanel.el.mask("Publishing account as a template...");
              }
              else {
                formPanel.el.mask("Please check the required fields");
                var tempFunction = function() {formPanel.el.unmask()};
                tempFunction.defer(1500);
              }
            }
        },{
          text: "Cancel",
          handler: function(me, event){
              xl.closeTabPanel('account_templates_new_nil')
            }
        }
        #{extra_button}
      ];
    `
  end

  def generate_form_panel
    %Q`
      #{self.render_tags_panel("account_template[tag_list]", @account_template, AccountTemplate.tags, {}, {:collapsible => false, :title => "Tags"}, true)}
      
      #{self.generate_features_selection_panel}
      
      var nameField = new Ext.form.TextField({
        name: "account_template[name]",
        value: #{@account_template.name.to_json},
        fieldLabel: "Name"
      });
      
      var demoUrlField = new Ext.form.TextField({
        name: "account_template[demo_url]",
        value: #{@account_template.demo_url.to_json},
        fieldLabel: "Demo url"
      });

      var industrySelectionStore = new Ext.data.SimpleStore({
        fields: ['display', 'value'],
        data: #{([["None", nil]] + AccountTemplate.industry_categories.map{|e| [e.name, e.id]}).to_json}
      });
      
      var industryField = new Ext.form.ComboBox({
        forceSelection: true,
        fieldLabel: "Industry",
        displayField: 'display',
        valueField: 'value',
        triggerAction: 'all',
        mode: 'local',
        allowBlank: false,
        forceSelection: true,
        name: "account_template[industry_id]",
        hiddenName: "account_template[industry_id]",
        store: industrySelectionStore, 
        value: #{(@account_template.industry ? @account_template.industry.id : nil).to_json}
      });

      var mainThemeSelectionStore = new Ext.data.SimpleStore({
        fields: ['display', 'value'],
        data: #{([["None", nil]] + AccountTemplate.main_theme_categories.map{|e| [e.name, e.id]}).to_json}
      });
      
      var mainThemeField = new Ext.form.ComboBox({
        forceSelection: true,
        fieldLabel: "Main theme",
        displayField: 'display',
        valueField: 'value',
        triggerAction: 'all',
        mode: 'local',
        allowBlank: false,
        forceSelection: true,
        name: "account_template[main_theme_id]",
        hiddenName: "account_template[main_theme_id]",
        store: mainThemeSelectionStore, 
        value: #{(@account_template.main_theme ? @account_template.main_theme.id : nil).to_json}
      });
      
      var updatingCategoryField = new Ext.form.Hidden({
        name: "account_template[updating_category]",
        value: "1"
      });
      
      var setupFeeField = new Ext.form.TextField({
        name: "account_template[setup_fee]",
        value: #{@account_template.setup_fee.to_s.to_json},
        fieldLabel: "Setup fee",
        width: 100
      });      
      
      var descriptionField = new Ext.form.TextArea({
        value: #{@account_template.description.to_json},
        name: "account_template[description]",
        fieldLabel: "Description",
        width:505
      });
      
      var descriptionPanel = new Ext.Panel({
        collapsible: false,
        title: "Description",
        width: 505,
        items: [ descriptionField ]
      });
      
      #{self.generate_form_buttons}

      var formPanel = new Ext.form.FormPanel({
        items: [
          {
            html: '<div class="notices" id="#{dom_id(@account_template)}_errorMessages"/>'
          },
          {
            layout: "column",
            items: [
              {columnWidth: .5, layout: "form", items: [nameField, demoUrlField, industryField, mainThemeField, updatingCategoryField, setupFeeField, descriptionPanel, tagsPanel] },
              {columnWidth: .5, layout: "form", items: [{html:"<b>Available features:</b>"}, featuresSelectionPanel]}
            ]
          }
        ],  
        tbar: formButtons,
        bbar: formButtons
      })
    `
  end

  def generate_features_selection_panel
    features_data = []
    total_price = Money.zero
    AccountTemplate.functionality_column_names.sort.each do |column|
      checked = @account_template.send(column)
      name = column.sub(/^f_/, "")
      fee = AccountModule.find_by_module(column.sub(/^f_/, "")).minimum_subscription_fee
      total_price += fee if checked
      features_data << { :column_name => column, :name => name.humanize, :checked => checked, :fee => fee.to_s }
    end
    total_price += @account_template.subscription_markup_fee
    subscription_data = [{:column_name => "subscription_markup_fee", :name => "Subscription markup fee", :checked => nil, :fee => @account_template.subscription_markup_fee.to_s}]
    summary_data = [{:column_name => "total", :name => "Total subscription fee", :checked => nil , :fee => total_price.to_s}]
    
    out = %Q`
      var featuresSelectionStore = new Ext.data.JsonStore({
        fields: ["column_name", "name", {name: "checked", type: "boolean"}, {name: "fee", type: "float"}],
        data: #{features_data.to_json}
      });

      var selectFeatureCheckColumn = new Ext.grid.CheckColumn({
        header: " ",
        dataIndex: 'checked',
        width: 25
      });
      
      var getTotalFee = function(){
        return summaryStore.getAt(0).get("fee");
      };
      
      var setTotalFee = function(fee){
        summaryStore.getAt(0).set("fee", fee);
      };

      selectFeatureCheckColumn.addListener("click", function(element, event, record){
        var totalFee = getTotalFee();
        var key = "account_template[" + record.get("column_name") + "]";
        if(record.get("checked")){
          globalParameters[key] = 1;
          totalFee += record.get("fee");
        }
        else{
          delete globalParameters[key];
          totalFee -= record.get("fee");
        }
        setTotalFee(totalFee);
      });
      
      var featuresSelectionGridPanel = new Ext.grid.EditorGridPanel({
        store: featuresSelectionStore,
        cm: new Ext.grid.ColumnModel([
          selectFeatureCheckColumn,
          {id: "account-template-module-name", width: 150, header: "Module name", dataIndex: 'name'},
          {id: "account-template-module-fee", header: "Fee (in CAD$)", dataIndex: "fee"}
        ]),
        plugins: selectFeatureCheckColumn,
        listeners:{
          render: function(me){
            featuresSelectionStore.each(function(record){
              if(record.get("checked")){
                var key = "account_template[" + record.get("column_name") + "]"
                globalParameters[key] = 1;
              }
            });
          }
        }
      });
      
      var subscriptionMarkupFeeStore = new Ext.data.JsonStore({
        fields: ["name", {name: "fee", type: "float"}, "column_name", "checked"],
        data: #{subscription_data.to_json}
      });
      
      var subscriptionMarkupFeeGrid = new Ext.grid.EditorGridPanel({
        hideHeaders: true,
        enableHdMenu: false,
        header: false,
        store: subscriptionMarkupFeeStore,
        clicksToEdit: 1,
        cm: new Ext.grid.ColumnModel([
          {id: "account-template-module-checked", width: 25, dataIndex: ''},
          {id: "account-template-module-name", width: 150, dataIndex: 'name'},
          {id: "account-template-module-fee", dataIndex: "fee", editor: new Ext.form.NumberField({
              autoShow: true, allowNegative: false, name: "account_template[subscription_markup_fee]",
              allowBlank: false, blankText: "Please insert non negative number"
            })
          }
        ]),
        listeners: {
          validateedit: function(event){
            var originalValue = event.originalValue;
            var newValue = parseFloat(event.value);
            var newTotalFee = getTotalFee() + newValue - originalValue;
            setTotalFee(newTotalFee);
          }
        }
      });

      var summaryStore = new Ext.data.JsonStore({
        fields: ["name", {name: "fee", type: "float"}, "column_name", "checked"],
        data: #{summary_data.to_json}
      });
      
      var summaryGrid = new Ext.grid.GridPanel({
        hideHeaders: true,
        enableHdMenu: false,
        header: false,
        store: summaryStore,
        cm: new Ext.grid.ColumnModel([
          {id: "account-template-module-checked", width: 25, dataIndex: ''},
          {id: "account-template-module-name", width: 150, dataIndex: 'name'},
          {id: "account-template-module-fee", dataIndex: "fee"}
        ])
      });
      
      var featuresSelectionPanel = new Ext.Panel({
        items: [featuresSelectionGridPanel, subscriptionMarkupFeeGrid, summaryGrid]
      });
    `
    out
  end

  def initialize_files_panel
    %Q`
      #{self.initialize_pictures_panel}
      #{self.initialize_multimedia_panel}
      #{self.initialize_other_files_panel}

      var attachImageButton = new Ext.Button({
          text: 'Attach image(s)',
          handler: function(button, event) {
            xl.widget.OpenImagePicker({
              showFrom: button.getId(),
              objectId: #{@account_template.id},
              objectType: 'account_template',

              thisObjectImagesUrl: #{images_account_template_path(@account_template).to_json},
              allImagesUrl: #{formatted_image_picker_assets_path(:format => :json).to_json},

              uploadUrl: #{upload_file_account_template_path(:id => @account_template.id).to_json},

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
            objectId: #{@account_template.id},
            objectType: 'account_template',
            imageClassification: 'multimedia',
            windowTitle: "Multimedia Picker",

            thisObjectImagesUrl: #{multimedia_account_template_path(@account_template).to_json},
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
            objectId: #{@account_template.id},
            objectType: 'account_template',
            imageClassification: 'other_files',
            windowTitle: "Other Files Picker",

            thisObjectImagesUrl: #{other_files_account_template_path(@account_template).to_json},
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
        url: #{images_account_template_path(:id => @account_template.id, :size => "mini").to_json},
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
        objectId: #{@account_template.id},
        objectType: 'account_template',
        height: xl.centerPanel.getInnerHeight()-xl.centerPanel.getBottomToolbar().getSize().height-78,
        imagesUrl: #{images_account_template_path(@account_template).to_json}
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
        url: #{multimedia_account_template_path(:id => @account_template.id, :size => "mini").to_json},
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
        objectId: #{@account_template.id},
        objectType: 'account_template',

        imagesUrl: #{multimedia_account_template_path(@account_template).to_json}
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
        url: #{other_files_account_template_path(:id => @account_template.id, :size => "mini").to_json},
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
        objectId: #{@account_template.id},
        objectType: 'account_template',

        imagesUrl: #{other_files_account_template_path(@account_template).to_json}
      });

      var otherFilePanel = imageViewerResult[0];
      var otherFilePanelStore = imageViewerResult[1];

      var otherFilesPanel = new Ext.Panel({
        hidden: true,
        items: [otherFilePanel]
      });
    `
  end  
end
