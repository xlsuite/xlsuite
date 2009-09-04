#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module ExtjsHelper
  PARTIES_PATH = "/admin/parties/\\d+".freeze
  PANEL_NOTIFICATION_CLASS_NAME = 'xlsuite-tabpanel-inside-notifications'.freeze
  
  def html_editor_image_video_embed_button(object)
%Q`
        {
          clickEvent:'mousedown',
          icon: "images/icons/image_add.png", 
          cls: 'x-btn-icon x-edit-image-video',
          tooltip: {
            title: 'Embed Image, MP3, or Video',
            text: 'Embed an image, mp3, or video file from File Manager',
            cls: 'x-html-editor-tip',
            tabIndex: -1
          },
          handler: function(){
            var insertTag = function(component, fileExtension, fileUrl){
              if(fileExtension.match(/(flv|swf|mp3)/i)){
                component.relayCmd('inserthtml', '{%media_player type:"'+fileExtension+'" url:"'+fileUrl+'"%}');
              }else{
                component.relayCmd('insertimage', fileUrl);
              }
            };
            
            var showFileManager = function(component){
              xl.widget.OpenSingleImagePicker('wysiwyg_embed_image', #{formatted_image_picker_assets_path(:format => :json).to_json}, "#{object.class.name}", 0, {
                windowTitle: "Please select a file to embed, or upload one...",
                beforeSelect: function(window){
                  window.el.mask("Processing...");
                },
                afterSelect: function(selectedRecord, window){
                  var fileName = selectedRecord.get("filename");
                  var fileUrl = selectedRecord.get("url");
                  var fileExtension = fileName.split(".").last();
                  
                  insertTag(component, fileExtension, fileUrl);
                  
                  window.el.unmask();
                  window.hide();
                },
                afterUpload: function(window){
                  window.el.unmask();
                  window.hide();
                },
                uploadCallback: function(response){
                  var fileExtension = response.file_name.split(".").last();
                  
                  insertTag(component, fileExtension, response.asset_download_path);
                }
              }, {doNotUpdateEl: true, content_type:"all"});
            };
            
            var showEmbedLink = function(component){
              Ext.MessageBox.show({
                msg: "Please enter the URL for the image, mp3, or flash video file:",
                width: 200,
                prompt: true,
                buttons: Ext.Msg.OKCANCEL,
                fn: function(btn, text){ if ( btn == 'ok' ) insertTag(component, text.split(".").last(), text);}
              });
            };
            
            Ext.MessageBox.show({
              title: "Embed Image",
              msg: "Do you want to use the file manager, or do you want to use a link?",
              width: 200,
              buttons: {yes:"File Manager", no:"URL"},
              fn: function(btn, text){ if ( btn == 'yes' ) showFileManager(component); else showEmbedLink(component);}
            });
          }
        }
`
  end
  
  def html_editor_copy_paste_from_word_button(object)
%Q`
        {
          clickEvent:'mousedown',
          icon: "images/icons/paste_word.png", 
          cls: 'x-btn-icon x-edit-image-video',
          tooltip: {
            title: 'Paste Microsoft Word',
            text: 'Copy selected text from Microsoft Word and paste in this window',
            cls: 'x-html-editor-tip',
            tabIndex: -1
          },
          handler: function(){
            tmpeditor = new Ext.form.HtmlEditor({
              width:520,
              height:150
            });
            win = new Ext.Window({ 
              title: "Paste from Microsoft Word - Copy text from WORD and paste with key CTR+V",  
              modal:true,
              width:537,
              height:220,
              shadow:true,
              resizable: false,
              plain:true,
  
              items: tmpeditor,
              buttons: [{
                text:'Paste',
                handler: function(){
                  var str = tmpeditor.getValue();
                  
                  str = str.replace(/MsoNormal/g,"");
                  str=String(str).replace(/<\\?\\?xml[^>]*>/g,"");
                  str=String(str).replace(/<\\/?o:p[^>]*>/g,"");
                  str=String(str).replace(/<\\/?v:[^>]*>/g,"");
                  str=String(str).replace(/<\\/?o:[^>]*>/g,"");
                  str=String(str).replace(/<\\/?st1:[^>]*>/g,"");
              
                  str=String(str).replace(/&nbsp;/g,"");
              
                  str=String(str).replace(/<\\/?SPAN[^>]*>/g,"");
                  str=String(str).replace(/<\\/?FONT[^>]*>/g,"");
                  str=String(str).replace(/<\\/?STRONG[^>]*>/g,"");
              
                  str=String(str).replace(/<\\/?H1[^>]*>/g,"");
                  str=String(str).replace(/<\\/?H2[^>]*>/g,"");
                  str=String(str).replace(/<\\/?H3[^>]*>/g,"");
                  str=String(str).replace(/<\\/?H4[^>]*>/g,"");
                  str=String(str).replace(/<\\/?H5[^>]*>/g,"");
                  str=String(str).replace(/<\\/?H6[^>]*>/g,"");
                
                  str=String(str).replace(/<\\/?P[^>]*><\\/P>/g,"");
                  str = str.replace(/<!--(.*)-->/g, "");
                  str = str.replace(/<!--(.*)>/g, "");
                  str = str.replace(/<!(.*)-->/g, "");
                  str = str.replace(/<\\\\?\\?xml[^>]*>/g,"");
                  str = str.replace(/<\\/?o:p[^>]*>/g,"");
                  str = str.replace(/<\\/?v:[^>]*>/g,"");
                  str = str.replace(/<\\/?o:[^>]*>/g,"");
                  str = str.replace(/<\\/?st1:[^>]*>/g,"");
                  str = str.replace(/style=\\"[^\\"]*\\"/g,"");
                  str = str.replace(/style=\\'[^\\"]*\\'/g,"");
                  str = str.replace(/lang=\\"[^\\"]*\\"/g,"");
                  str = str.replace(/lang=\\'[^\\"]*\\'/g,"");
                  str = str.replace(/class=\\"[^\\"]*\\"/g,"");
                  str = str.replace(/class=\\'[^\\"]*\\'/g,"");
                  str = str.replace(/type=\\"[^\\"]*\\"/g,"");
                  str = str.replace(/type=\\'[^\\"]*\\'/g,"");
                  str = str.replace(/href=\\'#[^\\"]*\\'/g,"");
                  str = str.replace(/href=\\"#[^\\"]*\\"/g,"");
                  str = str.replace(/name=\\"[^\\"]*\\"/g,"");
                  str = str.replace(/name=\\'[^\\"]*\\'/g,"");
                  str = str.replace(/ clear=\\"all\\"/g,"");
                  str = str.replace(/id=\\"[^\\"]*\\"/g,"");
                  str = str.replace(/title=\\"[^\\"]*\\"/g,"");
                  str = str.replace(/&nbsp;/g,"");
                  str = str.replace(/<div[^>]*>/g,"<p>");
                  str = str.replace(/<\\/?div[^>]*>/g,"</p>");
                  str = str.replace(/<span[^>]*>/g,"");
                  str = str.replace(/<\\/?span[^>]*>/g,"");
                  str = str.replace(/class=/g,"");
  
                  component.focus();
                  component.insertAtCursor(str);
                  win.close();
                }
              }]
            });
            win.show();
          }
        }
`
  end
  
  def party_auto_complete_display(p)
    p.display_name + "   (" + (p.main_email.email_address ? p.main_email.email_address : "") + ")"
  end
  
  def party_auto_complete_store
%Q!
    new Ext.data.Store({
             proxy: new Ext.data.HttpProxy(new Ext.data.Connection({url: #{formatted_extjs_auto_complete_parties_path(:format => :json).to_json}, method: 'get'})), 
             reader: new Ext.data.JsonReader({totalProperty: "total", root: "collection", id: "id"}, Ext.data.Record.create([
                 {name: 'display', mapping: 'display'},
                 {name: 'value', mapping: 'value'},
               ])
             )})
!
  end
  
  def create_grid_tbar_filter_field(store_name="ds")
    %Q`
      var filterField = new Ext.form.TextField({selectOnFocus: true, grow: false, emptyText: "Search"});
      filterField.on("specialkey",
        function(field, e) {
          if (e.getKey() == Ext.EventObject.RETURN || e.getKey() == Ext.EventObject.ENTER) {
            if (this.getValue().length < #{FulltextRow::MINIMUM_QUERY_LENGTH}){
              Ext.Msg.show({title: "Warning", msg: "Filter term cannot be shorter than #{FulltextRow::MINIMUM_QUERY_LENGTH} characters", buttons: Ext.Msg.OK, fn: function(btn, text){
                if (btn =="ok"){
                  field.focus();
                }
              }});
            }
            else{
              e.preventDefault();
              #{store_name}.baseParams['q'] = this.getValue();
              #{store_name}.reload({params: {start: 0, limit: #{store_name}.lastOptions.params.limit}});
            }
          }
        }
      );
    `
  end
  
  def create_grid_tbar_clear_button(store_name="ds")
    %Q`
      var clearButton = new Ext.Toolbar.Button({
        text: 'Clear',
        handler: function() {
          filterField.setValue("");
          #{store_name}.baseParams['q'] = "";
          #{store_name}.reload();
        }
      });
    `
  end
  
  def connection_error_message
    %Q`Ext.Msg.alert('Failure', "There was an error during execution. #{Time.now()}");`
  end
  
  def create_date_selection_data_stores
    %Q`
      var daysStore = new Ext.data.SimpleStore({
        fields: ['display', 'value'],
        data: #{([["day", ""]] + (1..31).map{|e| [e.to_s, e.to_s]}).to_json}
      });
      
      var monthsStore = new Ext.data.SimpleStore({
        fields: ['display', 'value'],
        data: [["month", ""], ["January", "1"], ["February", "2"], ["March", "3"], ["April", "4"], ["May", "5"], ["June", "6"], ["July", "7"], ["August", "8"], ["September", "9"], ["October", "10"], ["November", "11"], ["December", "12"]]
      });
      
      var yearsStore = new Ext.data.SimpleStore({
        fields: ['display', 'value'],
        data: #{([["year", ""]] + (1900..Time.now.year).map{|e| [e.to_s, e.to_s]}).to_json}
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
      var tbarbbarButtons = [{
        text: 'Save',
        handler: function(me, event){
            #{maskPanel}.el.mask('Saving...');
            xl.maskedPanels.push(#{maskPanel});
            formPanel.getForm().doAction('submit',
              {
                url: #{url.to_json}, 
                method: '#{options[:method]}', 
                success: function(form, action) {
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
                  #{refresh_grid_datastore_of(object.class.name.underscore)};
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
                },
                failure: function(form, action) {
                  response = action.result;
                  #{maskPanel}.el.unmask();
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
                success: function(form, action) {
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
                  $("status-bar-notifications").innerHTML = response.flash; 
                  #{refresh_grid_datastore_of(object.class.name.underscore)};
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
                },
                failure: function(form, action) {
                  xl.logXHRFailure;
                  response = action.result;
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
                #{render_cancel_close_tabs};
              }
            }})
          }
          else{
            #{render_cancel_close_tabs};
          }
        }
      }];
  `
  end
  
  def render_img_tag_or_none(id)
    if id.nil?
      return "<div style=\"height: 140px; width: 140px; background-color: #EEE;\">&nbsp;</div>"
    else
      return "<img src=\"#{download_asset_path(:id => id)}?size=small\" height=\"140\" />"
    end
  end

  def render_tags_panel(name, object, tags_selection, options={}, panel_options={}, no_ajax=false)
    text_area = render_tags_text_area(name, object, options, no_ajax)
    
    panel_options.reverse_merge!(:collapsible => true, :title => "TAGS")
     
    out = %Q`
      var tagsSelectionPanel = #{render_tags_selection(name, object, tags_selection, no_ajax, options)};
      
      var tagsPanelTextArea = #{text_area};

      var tagsPanel = new Ext.Panel({
        collapsible: #{panel_options[:collapsible].to_json},
        title: #{panel_options[:title].to_json},
        width: #{options[:width] || 505 },
        items: [ tagsPanelTextArea,
          tagsSelectionPanel
        ]
      });
    `
    out
  end
  
  def render_tags_text_area(name, object, options={}, no_ajax=false)
    if object.kind_of?(String)
      field_options = options.reverse_merge(:type => "textarea", :value => "", :width => 505,
        :name => "tag_list", :inline_form => options[:inline_form] || "form", :id => "tags_text_area_#{object}_ID", :after_edit => "function(){}")
      JsonLiteral.new("xl.widget.InlineActiveField({form: #{field_options.delete(:inline_form)}, afteredit: #{field_options.delete(:after_edit)}, field: #{field_options.to_json}})")
    else
      if object.new_record? || no_ajax
        %Q`
        new Ext.form.TextArea({
          width: #{options[:width] || 505 },
          name: #{name.to_json},
          value: #{object.tag_list.to_json},
          fieldLabel: #{options[:fieldLabel].to_json},
          id: "tags_text_area_#{dom_id(object)}"
        })`
      else
        field_options = options.reverse_merge(:type => "textarea", :value => object.tag_list, :width => 505,
          :name => "tag_list", :inline_form => options[:inline_form] || "form", :id => "tags_text_area_#{dom_id(object)}", :after_edit => "function(){}")
        JsonLiteral.new("xl.widget.InlineActiveField({form: #{field_options.delete(:inline_form)}, afteredit: #{field_options.delete(:after_edit)}, field: #{field_options.to_json}})")
      end
    end
  end
  
  def render_tags_selection(name, object, tags_selection, no_ajax=false, options={})
    tags_list = ""
    if object.kind_of?(String)
      tags_list = tags_selection.collect {|e| link_to_function(e.name, "applyTagTo(#{e.name.to_json}, $('tags_text_area_#{object}_ID').id)", :class=>"tags_panel_selection")}.join(", ")
    else
      if object.new_record? || no_ajax
        tags_list = tags_selection.collect {|e| link_to_function(e.name, "applyTagTo(#{e.name.to_json}, $('tags_text_area_#{dom_id(object)}').id)", :class=>"tags_panel_selection")}.join(", ")
      else
        tags_list = tags_selection.collect {|e| link_to_function(e.name, "var textAreaId = $('tags_text_area_#{dom_id(object)}').id; $(textAreaId).focus(); applyTagTo(#{e.name.to_json}, textAreaId); this.focus()", :class=>"tags_panel_selection")}.join(", ")
      end
    end
    
    %Q`
      new Ext.Panel({
        width: #{options[:width] || 505 },
        height: 100,
        autoScroll: true,
        frame: true,
        html: #{tags_list.to_json} ,
        style: #{options[:style].to_json}
      })
    `
  end
  
  def create_countries_and_states_store  
    %Q`
      var countriesStore = new Ext.data.SimpleStore({
        fields: ['value', 'id'],
        data: #{AddressContactRoute::COUNTRIES.map(&:to_a).to_json}
      });
      
      var statesStore = new Ext.data.SimpleStore({
        fields: ['value', 'id'],
        data: #{AddressContactRoute::STATES.map(&:to_a).to_json}
      });
    `
  end

  def get_half_height_size_of_tabpanel
    %Q`(xl.centerPanel.getInnerHeight()-parent.xl.centerPanel.getBottomToolbar().getSize().height)/2`
  end

  def to_extjs_date_field_value(input_time)
    time = Time.now
    time = input_time if !input_time.blank? && input_time.kind_of?(Time)
    time.strftime("%m/%d/%Y")
  end

  def refresh_grid_datastore_of(model_name)
    %Q`
      xl.runningGrids.each(function(pair){
        var grid = pair.value;
        var dataStore = grid.getStore();
        if (dataStore.proxy.conn.url.match(new RegExp('#{model_name.underscore.pluralize}\\.json', "i"))) {
          dataStore.reload();
        }
      })
    `
  end
  
  def mask_grid_datastore_of(model_name, message)
    %Q`
      xl.runningGrids.each(function(pair){
        var grid = pair.value;
        var dataStore = grid.getStore();
        if (dataStore.proxy.conn.url.match(new RegExp('#{model_name.pluralize}\\.json$', "i"))) {
          grid.el.mask(#{message.to_json});
          xl.maskedPanels.push(grid);
        }
      })
    `
  end

  def mask_grid_with_key(key, message)
    %Q`
      object = xl.runningGrids.get(#{key.to_json})
      object.el.mask(#{message.to_json});
      xl.maskedPanels.push(object);
    `
  end

  def unmask_grid_datastore_of(model_name)
    %Q`
      xl.runningGrids.each(function(pair){
        var grid = pair.value;
        var dataStore = grid.getStore();
        if (dataStore.proxy.conn.url.match(new RegExp('#{model_name.pluralize}\\.json$', "i"))) {
          grid.el.unmask();
          xl.maskedPanels.remove(grid.el);
        }
      })
    `
  end
  
  def unmask_grid_with_key(key)
    %Q`
      var temp = xl.runningGrids.get(#{key.to_json});
      if(temp){
        temp.el.unmask();
        xl.maskedPanels.remove(temp.el);
      }
    `
  end

  def refresh_grid_datastore_with_key(key)
    %Q`
      xl.runningGrids.get('#{key}').getStore().reload();
    `
  end

  def close_tab_panel(tab_panel_id)
    "xl.closeTabPanel('#{tab_panel_id}');"
  end
  
  def send_default_get_ajax_request(source)
    %Q`
      new Ajax.Request('#{source}', {asynchronous:true, evalScripts:true, method:'get'});
    `
  end

  def render_inside_panel_notifications_container(class_name=PANEL_NOTIFICATION_CLASS_NAME)
    %Q`
      <div class="#{class_name}"></div>
    `
  end
  
  def update_inside_panel_notifications(id=nil)
    id = create_id_from_params unless id
    %Q`
      var notificationElement = $$('##{id} .#{PANEL_NOTIFICATION_CLASS_NAME}').first();
      if (notificationElement) {
        notificationElement.innerHTML = #{show_flash_messages.to_json};
      }
    `
  end
  
  def create_function_using_ajax_response(&block)
    mapped_id = create_id_from_params
    result = %Q`
    try {
        function #{mapped_id}(){
    `
    result << block.call if block
    result << %Q`
        }
        #{mapped_id}();
      }
    catch (error) {
      xl.log("Error Evaluating #{mapped_id}:");
      xl.log(error);
    }  
    `
  end
  
  # This helper method cannot be used in RHTML templates because the block is not captured
  def create_tab_using_ajax_response(title, prepend="", &block)
    mapped_id = create_id_from_params
    result = %Q`
    try {
      function #{mapped_id}(){
        var mappedId = "#{mapped_id}";
  
        if (xl.runningTabs.get(mappedId)) {
          xl.runningTabs.get(mappedId).show();
        }
        else {
          var newPanel = new Ext.Panel({
            id: mappedId,
            cls: 'tab-panel-wrapper',
            region: "center",
            title: #{title.to_json},
            titlebar: true,
            layout: 'fit',
            autoWidth: true
          });
  
          newPanel.on('beforedestroy', function() {
            newPanel.items.clear();
            xl.runningTabs.unset(mappedId);
            if (xl.runningTabs.size() == 0){
              xl.backgroundPanel.show();
            }
          });          
          
          xl.resizeTabPanel();
          xl.tabPanel.add(newPanel).show();
          xl.runningTabs.set(mappedId, newPanel);  
    `
    result << block.call if block

    result << %Q`
          xl.viewport.render();
          xl.resizeTabPanel();
          newPanel.syncSize();
          newPanel.on("show", function(){
            xl.viewport.render();
            xl.resizeTabPanel();
          });
          
          // Execute the post-render callback if present
          if (typeof _afterRenderCallback == 'function') { _afterRenderCallback(); }
            
          #{prepend}  
        }
      } // end #{mapped_id}()
      
      #{mapped_id}();
    } catch (error) {
      xl.log("Error Evaluating #{mapped_id}:");
      xl.log(error);
    }
    `

    result
  end
  
  def generate_inside_tab_panel_id(*args)
    self.create_id_from_params(:inside, args)
  end

  def create_id_from_params(*args)
    array = [params[:controller].gsub("/","_"), params[:action]]
    params_id = params[:id].blank? ? ( params[:ids].blank? ? "nil" : params[:ids].split(',').to_a.join('_') ) : params[:id]
    array << params_id
    args.each do |arg|
     array << arg.to_s.downcase 
    end
    array.join("_")
  end

  def link_to_function_in_iframe(iframe_id, *args)
    args[1] = "$('#{iframe_id}').contentWindow." + args[1]
    link_to_function(*args)
  end

  def open_last_incoming_request_tab
    return if last_incoming_request.blank?
    javascript_tag %Q!
        Ext.onReady(function(){
          xl.createTab("#{last_incoming_request}");
        });
    !
  end

  def render_using_extjs_layout
    return if @current_domain.new_record? || @current_domain.account.confirmation_token
    javascript_tag %Q~
      if (!parent.location.pathname.match(new RegExp("/admin$", "i"))) {
        window.location.href="#{blank_landing_url}";
      }
    ~
  end

  def update_notices_using_ajax_response(options={})
    options.reverse_merge!({:on_root => false})
    on_root = options[:on_root] ? "" : "parent."
    %Q~
      #{on_root}$("status-bar-notifications").innerHTML = "#{render_plain_flash_messages}";
    ~
  end

  def get_default_grid_height(parent=true)
    if parent
      "parent.xl.centerPanel.getInnerHeight()-parent.xl.centerPanel.getBottomToolbar().getSize().height-15"
    else
      "xl.centerPanel.getInnerHeight()-xl.centerPanel.getBottomToolbar().getSize().height-15"
    end
  end
  
  def get_center_panel_width
    "xl.centerPanel.getInnerWidth()"
  end

  def render_plain_flash_messages
    flashes = []
    flashes << flash[:notice]
    flashes << flash[:message]
    flashes << flash[:warning]
    flashes.flatten.compact.map(&:strip).join(", ")
  end

  def update_notices
    javascript_tag %Q~
      var iframe_object = parent.Ext.get('#{@_current_page_uri}');
      if (!iframe_object) {
        iframe_object = parent.Ext.get('#{@_current_page_url}');
      }
      if (iframe_object) {
        iframe_object.on("load", function(){
          parent.$("status-bar-notifications").innerHTML = "#{e(render_plain_flash_messages)}"
        });
      }
    ~
  end

  def disable_iframe_scrolling
    javascript_tag %Q~
      Ext.EventManager.onDocumentReady( function(){
        var uri = "#{@_current_page_uri}";
        var url = "#{@_current_page_url}";

        var iframeId = parent.xl.generateIframeIdFromSource(uri);
        if (!iframeId) {
          iframeId = parent.xl.generateIframeIdFromSource(url);
        }

        var iframe_object = parent.$(uri);
        if (!iframe_object) {
          iframe_object = parent.$(url);
        }
        if (!iframe_object) {
          iframe_object = parent.$(iframeId);
        }

        if (iframe_object) {
          iframe_object.scrolling = "no";
        }
      });
    ~
  end

  def initialize_east_console_title()
    title = if @party
        "Related to " + @party.name.to_s
      else
        "Record Dashboard"
      end
    %Q!
      xl.setEastTitle("#{title}", $('current-displayed-iframe-source').value);
    !
  end


  # TODO : need to clean this method especially the javascript code
  def initialize_center_header(default_title=nil)
    title = if default_title.blank?
      params_clone = params.clone
      temp = params_clone.delete(:controller).humanize + " | " + params_clone.delete(:action).humanize
      @title.blank? ? temp : @title
    else
      text
    end

    # This removes the http://mydomain.ext; the resulting string
    # matches the id of an iframe on the page and thusly the corresponding
    # titlebar spans for that. I don't think we can just do this.id
    # in the JS because I don't think this has any scope
    uri = @_current_page_uri
    url = @_current_page_url

    out = []
    javascript_tag %Q~
      // This is the IFRAME's documentReady
      if(parent.xl)
      {
        Ext.EventManager.onDocumentReady(
          function(){
            // Set up the variables for convenience
            var uri = '#{uri}';
            var url = '#{url}';
            var title = '#{title}';
            var iframeId = parent.xl.generateIframeIdFromSource(uri);
            if (!iframeId) {
              iframeId = parent.xl.generateIframeIdFromSource(url);
            }

            // Ext.Panels are stored in parent.xl.runningTabs
            var panel_via_uri= parent.xl.runningTabs.get(uri);
            var panel_via_url = parent.xl.runningTabs.get(url);
            var panel_via_iframeId = parent.xl.runningTabs.get(iframeId);

            // Check to see which method is needed
            // and set iframeId accordingly
            if (panel_via_uri) {
              panel_via_uri.setTitle(title);
              iframeId = uri;
            }
            if (panel_via_url) {
              panel_via_url.setTitle(title);
              iframeId = url;
            }
            if (panel_via_iframeId){
              panel_via_iframeId.setTitle(title);
            }
          }
        )
      }
    ~
  end

  def change_centre_iframe_src(path, default_id=nil)
    if default_id
      "xl.createTab('#{path}', '#{default_id}')"
    else
      "xl.createTab('#{path}')"
    end
  end

  def create_tab_as_div(path)
    "xl.createTabAsDiv('#{path}')"
  end
end
