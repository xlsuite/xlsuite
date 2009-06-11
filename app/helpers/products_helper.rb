#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module ProductsHelper
  def initialize_delivery_panel
    accessible_files_path = formatted_product_items_path(:format => :json, :type => "Asset", :product_id => @product.id).gsub("&amp;","&").to_json
    accessible_groups_path = formatted_product_items_path(:format => :json, :type => "Group", :product_id => @product.id).gsub("&amp;", "&").to_json
    accessible_blogs_path = formatted_product_items_path(:format => :json, :type => "Blog", :product_id => @product.id).gsub("&amp;", "&").to_json
    files_path = formatted_image_picker_assets_path(:format => :json).to_json
    %Q`
      var addFileButton = new Ext.Toolbar.Button({
        text: "Add file",
        handler: function(btn){
          xl.widget.OpenSingleImagePicker("", #{files_path}, "ProductItem", "#{@product.id}", 
            {
              afterSelect: function(selectedRecord, filePickerWindow){
                Ext.Ajax.request({
                  url: #{product_items_path.to_json},
                  method: "POST",
                  params: {item_type:"Asset", item_id:selectedRecord.get("id"), product_id:#{@product.id}},
                  success: function(response){
                    var response = Ext.util.JSON.decode(response.responseText);
                    if(response.success){
                      accessibleFilesDataStore.reload();
                    }
                  }
                });
              },
              windowTitle: "Choose a file"
            },
            {content_type: "all", doNotUpdateEl: true}
          )
        }
      });
      
      var removeFileButton = new Ext.Toolbar.Button({
        text: "Remove",
        disabled: true,
        handler: function(btn){
          Ext.Ajax.request({
            url: #{destroy_collection_product_items_path.to_json},
            method: "delete",
            params: {item_ids: selectedAccessibleFileIds.join(","), item_type: "Asset", product_id: #{@product.id}},
            success: function(response){accessibleFilesDataStore.reload()}
          })
        }
      });
      
      // create file record
      var FileRecord = new Ext.data.Record.create([
        {id: 'id', name: 'id', mapping: 'id'},
        {id: 'dom_id', name: 'dom_id', mapping: 'dom_id'},
        {id: 'label', name: 'label', mapping: 'label'},
        {id: 'type', name: 'type', mapping: 'type'},
        {id: 'folder', name: 'folder', mapping: 'folder'},
        {name: 'size', mapping: 'size'},
        {id: 'path', name: 'path', mapping: 'path'},
        {id: 'z_path', name: 'z_path', mapping: 'z_path'},
        {id: 'absolute_path', name: 'absolute_path', mapping: 'absolute_path'},
        {name: 'notes', mapping: 'notes'},
        {name: 'tags', mapping: 'tags'},
        {name: 'created_at', mapping: 'created_at'},
        {name: 'updated_at', mapping: 'updated_at'},
        {name: 'url', mapping: 'url'}      
      ]);

      // data reader to parse the json response
      var accessibleFilesReader = new Ext.data.JsonReader({totalProperty: "total", root: "collection", id: "id"}, FileRecord);
      // set up connection of the data
      var accessibleFilesConnection = new Ext.data.Connection({url: #{accessible_files_path}, method: 'get'});
      var accessibleFilesProxy = new Ext.data.HttpProxy(accessibleFilesConnection);
      // set up the data store and then send request to the server
      var accessibleFilesDataStore = new Ext.data.Store({
        proxy: accessibleFilesProxy,
        reader: accessibleFilesReader,
        remoteSort: true
      });

      var accessibleFilesExpander = new xg.RowExpander({ contains: ["notes", "tags", "updated_at", "created_at", "id", "absolute_path", "z_path"],
        tpl : new Ext.Template(
          '<table><tr><td>',
          '<img src="{absolute_path}"/></td><td>',
          '<div>{notes}</div>',
          '<div>Tags: {tags}</div>',
          '<div>Updated at: {updated_at}</div>',
          '<div>Created at: {created_at}</div>',
          '<div>Absolute download path: {absolute_path}</div>',
          '<div>Asset URL liquid tag: {% asset_url file_path:"{z_path}" size:"full" %}</div></td></tr></table>'
        )
      });
      
      var accessibleFilesToolbar = new Ext.Toolbar({
        cls: "toolbar_auto_width",
        items: ["Accessible file(s)", addFileButton, removeFileButton]
      });
      
      var selectedAccessibleFileIds = null;
      
      var accessibleFilesGrid = new Ext.grid.GridPanel({
        store: accessibleFilesDataStore,
        cm: new Ext.grid.ColumnModel([ accessibleFilesExpander,
            {header: "Label", width: 250, sortable: false, dataIndex: 'label'},
            {header: "Type", width: 125, sortable: false, dataIndex: 'type'},
            {header: "Size", width: 75, sortable: false, dataIndex: 'size'},
            {header: "Folder", width: 100, sortable: false, dataIndex: 'folder'},
            {id: 'file-manager-path', header: "Path", width: 140, sortable: false, dataIndex: 'path', editor: 
              new Ext.form.TextField({
                listeners: {
                  'focus': function(me){
                    me.selectText();
                  } 
                }
              })
            },
            {header: "Updated at", width: 100, sortable: true, dataIndex: 'updated_at'}
          ]),
        viewConfig: {
          forceFit: false
        },
        plugins: accessibleFilesExpander,
        autoScroll: true,
        autoWidth: true,
        autoExpandColumn: 'file-manager-path',
        height: 200,
        footer: true,
        iconCls: 'icon-grid',
        sm: new Ext.grid.RowSelectionModel({
              listeners: {
                selectionchange: function(selmodel){
                  var selectedRecords = selmodel.getSelections();
                  var ids = new Array();
                  selectedRecords.each(function(e){ids.push(e.get("id"))});
                  selectedAccessibleFileIds = ids;
                  if(ids.length>0){
                    removeFileButton.enable();
                  }
                  else{
                    removeFileButton.disable();
                  }
                }
              }
          }),
        loadMask: true,
        tbar: accessibleFilesToolbar,
        listeners: {
          render: function(grid){
            accessibleFilesDataStore.load();
          },         
        }
      });
      
      var accessibleGroupsRootTreeNode =  new Ext.tree.AsyncTreeNode({
        text: "Group - Root",
        expanded: true,
        id: 0
      });

      var accessibleGroupsTreePanel = new Ext.tree.TreePanel({
        title: "Accessible Groups",
        root: accessibleGroupsRootTreeNode,
        rootVisible: false,
        autoScroll: true,
        loader: new Ext.tree.TreeLoader({
          requestMethod: "GET",
          url: #{accessible_groups_path},
          baseAttrs: {uiProvider: Ext.tree.TreeCheckNodeUI}
        }),
        listeners: {
            check: function(node, checked){
              var params = {product_id: #{@product.id}, item_type: "Group"};
              var method = null;
              var url = null;
              if(checked){
                url = #{product_items_path.to_json};
                method = "POST"
                params.item_id = node.id;
              }
              else{
                url = #{destroy_collection_product_items_path.to_json}
                method = "DELETE";
                params.item_ids = node.id;
              }
              Ext.Ajax.request({
                url: url,
                method: method,
                params: params
              });
            },
            render: function(cpt){
              cpt.setHeight(cpt.ownerCt.ownerCt.getSize().height);
            }
          }
      });
      
      
      //////////////////////////////////////////// BLOGS SELECTION PANEL ////////////////////////////////////////////////////////
      var BlogRecord = new Ext.data.Record.create([
        {name: 'id', mapping: 'id'},
        {name: 'title', mapping: 'title'},
        {name: 'subtitle', mapping: 'subtitle'},
        {name: 'label', mapping: 'label'},
        {name: 'author_name', mapping: 'author_name'},
        {name: 'checked', mapping: 'checked'}
      ]);
      
      var accessibleBlogsGridPanelReader = new Ext.data.JsonReader({totalProperty: "total", root: "collection", id: "id"}, BlogRecord);
      var accessibleBlogsGridPanelConnection = new Ext.data.Connection({
        url: #{accessible_blogs_path}, 
        method: 'get'
      });
      var accessibleBlogsGridPanelProxy = new Ext.data.HttpProxy(accessibleBlogsGridPanelConnection);
      var accessibleBlogsGridPanelStore = new Ext.data.Store({
        proxy: accessibleBlogsGridPanelProxy,
        reader: accessibleBlogsGridPanelReader
      });

      var accessibleBlogsGridPanelCheckColumn = new Ext.grid.CheckColumn({
        dataIndex: 'checked',
        width: 30
      });
      
      accessibleBlogsGridPanelCheckColumn.addListener("click", function(element, event, record){
        var params = {product_id: #{@product.id}, item_type: "Blog"};
        var method = null;
        var url = null;
        if(record.get("checked")){
          url = #{product_items_path.to_json};
          method = "POST"
          params.item_id = record.get("id");
        }
        else{
          url = #{destroy_collection_product_items_path.to_json}
          method = "DELETE";
          params.item_ids = record.get("id");
        }
        Ext.Ajax.request({
          url: url,
          method: method,
          params: params
        });
      });
      
      var accessibleBlogsGridPanel = new Ext.grid.GridPanel({
        title: "Accessible Blogs",
        store: accessibleBlogsGridPanelStore,
        cm: new Ext.grid.ColumnModel([
            accessibleBlogsGridPanelCheckColumn,
            {id: "blog-title", width: 100, header: "Title", dataIndex: 'title'},
            {id: "blog-author_name", width: 100, header: "Author", dataIndex: 'author_name'}
          ]),
        autoScroll: true,
        width: "100%",
        plugins: accessibleBlogsGridPanelCheckColumn,
        selModel: new Ext.grid.RowSelectionModel,
        viewConfig: { autoFill: true },
        autoExpandColumn: "blog-title",
        loadMask: true,
        listeners: {
          render: function(grid){
            grid.setHeight(grid.ownerCt.ownerCt.getSize().height);
            accessibleBlogsGridPanelStore.load();
          }
        }
      });
      
      ///////////////////////////////////////////////GENERAL LAYOUT///////////////////////////////////////////////////
      
      var lowerDeliveryPanel = new Ext.Panel({
        layout: "column",
        items: [
          {columnWidth: 0.5, items:[accessibleBlogsGridPanel]},
          {columnWidth: 0.5, items:[accessibleGroupsTreePanel]}
        ],
        listeners: {
          render: function(cpt){
            cpt.setHeight(cpt.ownerCt.getSize().height-accessibleFilesGrid.getSize().height);
          }
        }
      });

      var deliveryPanel = new Ext.Panel({
        items: [accessibleFilesGrid, lowerDeliveryPanel],
        listeners: {
          render: function(cpt){
            cpt.setHeight(cpt.ownerCt.getSize().height-5);
          }
        }
      });
    `
  end

  def render_product_tabpanel_items
    %Q`
    [{
      title: 'Display Info',
      autoScroll: true,
      autoLoad: {url:#{display_info_product_path(@product).to_json}, scripts:true}
    },{
      title: 'Discounts',
      autoScroll: true,
      autoLoad: {url:#{discounts_product_path(@product).to_json}, scripts:true}
    },{
      title: 'Shipping',
      html: 'Shipping content'
    },{
      title: 'Product Relations',
      html: 'Product Relations content'
    },{
      title: 'Supply',
      autoScroll: true,
      layout: 'ux.rowfit',
      items: [supply_suppliersGridPanel, supply_poGridPanel]
    },{
      title: 'Receiving & Storage',
      html: 'Receiving & Storage content'
    },{
      title: 'Sales History',
      html: 'Sales History content'
    },{
      title: 'Break-Even',
      html: 'Break-Even content'
    },{
      title: 'Images',
      html: 'Images content'
    }]
    `
  end
  
  def product_tag_after_update
    return nil if @product.new_record?
    %Q`
      function() {
        var params = {};
        params["product[tag_list]"] = $F("#{typed_dom_id(@product, :tag_list, :field)}");
        Element.show("#{typed_dom_id(@product, :tag_list, :indicator)}");
        new Ajax.Request("#{product_path(@product)}", {
          method: 'put',
          onComplete: function() { Element.hide("#{typed_dom_id(@product, :tag_list, :indicator)}"); },
          submit: "#{dom_id(@product)}_display_info", parameters: params
        });
      }
    `
  end
  
  def render_product_categories_actions
    out = []
    js_input_params = [typed_dom_id(@product, :category_ids).to_json]
    js_input_params << product_path(@product).to_json unless @product.new_record?
    js_input_params = js_input_params.join(",")
    
    out << link_to_function('&#x21d0; Add',
            %Q`addToProductCategorySelection('#{dom_id(@product)}_available_categories', '#{dom_id(@product)}_selected_categories', #{js_input_params})`,
            :class => 'action')
    out << link_to_function('Remove &#x21d2;',
            %Q`removeFromProductCategorySelection('#{dom_id(@product)}_selected_categories', #{js_input_params})`,
            :class => 'action')
    out << link_to_function('Clear Selection',
            %Q`clearProductCategorySelection('#{dom_id(@product)}_selected_categories', #{js_input_params})`,
            :class => 'action')
    out.join("")
  end
  
  def product_checkbox_js(method_name)
    return nil if @product.new_record?
    %Q`
      var check = "0";
      if (this.checked) {
        check = "1";
      }
      var params = {};
      params["product[#{method_name}]"] = check;
        Element.show("#{typed_dom_id(@product, method_name.to_sym, :indicator)}");
        new Ajax.Request("#{product_path(@product)}", {
          method: 'put',
          onComplete: function() { Element.hide("#{typed_dom_id(@product, method_name.to_sym, :indicator)}"); },
          parameters: params
        });
    `
  end
  
  def render_ids_selection_field
    %Q`
      <select>
        <option>Internal</option>
        <option>ISBN</option>
        <option>Model</option>
        <option>Sku</option>
        <option>UPC</option>
      </select>
    `
  end
  
  def render_measurement_units_selection_field
    %Q`
      <select>
        <option>Imperial</option>
        <option>Metric</option>
      </select>
    `
  end    
end
