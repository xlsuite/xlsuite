#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module RolesHelper
  def info_panel_items
    out = ["mainInfoPanel", "effectivePermissionsGridPanel"]
    out += ["selectPermissionsGridPanel", "deniedPermissionsGridPanel"] if @current_user_can_edit_party_security
    out.join(", ")
  end

  def initialize_effective_permissions_grid_panel
    height = if @current_user_can_edit_party_security
        "((#{get_default_grid_height(nil)}-35)/2-1)"
      else
        "((#{get_default_grid_height(nil)}-35)-1)"
      end
    %Q`
      var EffectivePermissionRecord = new Ext.data.Record.create([
        {name: 'id', mapping: 'id'},
        {name: 'name', mapping: 'name'}
      ]);

      var formattedEffectivePermissionsPath = #{formatted_effective_permissions_role_path(:id => @role.id, :format => "json").to_json};

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
            {id: "role-effective-permission-name", header: "Name", dataIndex: 'name'}
          ]),
        disableSelection: true,
        height: #{height},
        width: (#{self.get_center_panel_width}/2-9),
        viewConfig: {autoFill: true},
        autoExpandColumn: "role-effective-permission-name",
        frame: true,
        loadMask: true
      });

      xl.runningGrids.set("#{typed_dom_id(@role, :effective_permissions)}", effectivePermissionsGridPanel);
      newPanel.on("destroy", function(){
        xl.runningGrids.unset("#{typed_dom_id(@role, :effective_permissions)}");
      });
    `
  end
  
  def initialize_selected_permissions_grid_panel
    return "" unless @current_user_can_edit_party_security
    %Q`
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
      
      var selectPermissionsGridPanel = new Ext.grid.EditorGridPanel({
        title: "Selected Permissions",
        store: selectPermissionsDataStore,
        cm: new Ext.grid.ColumnModel([
            selectPermissionsCheckColumn,
            {id: "role-select-permission-name", header: "Name", dataIndex: 'name'}
          ]),
        height: ((#{get_default_grid_height(nil)}-35)/2-1),
        width: (#{get_center_panel_width}/2-9),
        plugins: selectPermissionsCheckColumn,
        autoExpandColumn: "role-select-permission-name",
        frame: true
      });

      xl.runningGrids.set("#{typed_dom_id(@role, :select_permissions)}", selectPermissionsGridPanel);
      newPanel.on("destroy", function(){
        xl.runningGrids.unset("#{typed_dom_id(@role, :select_permissions)}");
      });
    `
  end
  
  def initialize_denied_permissions_grid_panel
    return "" unless @current_user_can_edit_party_security
    %Q`
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
        width: 25
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
        height: ((#{get_default_grid_height(nil)}-35)/2-1),
        width: (#{get_center_panel_width}/2-9),
        plugins: deniedPermissionsCheckColumn,
        autoExpandColumn: "denied-permission-name",
        frame: true
      });

      xl.runningGrids.set("#{typed_dom_id(@role, :denied_permissions)}", deniedPermissionsGridPanel);
      newPanel.on("destroy", function(){
        xl.runningGrids.unset("#{typed_dom_id(@role, :denied_permissions)}");
      });
    `
  end
end
