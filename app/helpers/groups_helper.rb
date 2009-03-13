#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module GroupsHelper
  def tab_panel_items
    out = [%Q`{title: "Info", items: [mainInfoPanel]}`]
    out << [%Q`{title: "Security", items: [securityPanel], listeners: {show: function(panel){xl.viewport.render();}} }`] if @current_user_can_edit_party_security
    out << [%Q`{title: "Members (#{@group.members.size})", items: [membersGrid], listeners: {show: function(panel){xl.viewport.render();}} }`]
    out.join(", ")
  end

  def initialize_members_panel
    limit = 50
    %Q`
      // create file record
      var MemberRecord = new Ext.data.Record.create([
        {name: 'id', mapping: 'id'},
        {name: 'display-name', mapping: 'display-name'},
        {name: 'email-address', mapping: 'email-address'},
        {name: 'phone', mapping: 'phone'},
        {name: 'link', mapping: 'link'},
        {name: 'checked', mapping: 'checked'}
      ]);
      
      // data reader to parse the json response
      var reader = new Ext.data.JsonReader({totalProperty: "total", root: "collection", id: "id"}, MemberRecord);

      // set up connection of the data
      var connection = new Ext.data.Connection({url: #{formatted_parties_path(:base_group_id => @group.id, :format => :json).to_json}, method: 'get'});
      var proxy = new Ext.data.HttpProxy(connection);

      // set up the data store and then send request to the server
      var membersStore = new Ext.data.Store({proxy: proxy, reader: reader, remoteSort: true, baseParams: {q: '', group_id: #{@group.id}}});

      // set up the ext grid object
      var xg = Ext.grid;

      // define paging toolbar that is going to be appended to the footer of the grid panel
      var paging = new Ext.PagingToolbar({
        store: membersStore,
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
            membersStore.baseParams['q'] = this.getValue();
            membersStore.reload({params: {start: 0, limit: #{limit}}});
          }
        }
      );
      
      var filterByStore = new Ext.data.SimpleStore({
        fields: ['display', 'value'],
        data: #{[['All', 'all'], [@group.name, @group.id]].to_json}
      });
      
      var filterBySelection = new Ext.form.ComboBox({
        hiddenName: 'filter_by',
        displayField: 'display', 
        valueField: 'value',
        fieldLabel: 'Filter By',
        emptyText: 'Groups',
        width: 110,
        value: #{@group.id},
        store: filterByStore, 
        editable : false,
        triggerAction: 'all',
        mode: 'local',
        listeners: {
          'select': function(me, record, index){
            membersStore.baseParams['q'] = filterField.getValue();
            membersStore.baseParams['group_id'] = record.data.value;
            membersStore.reload({params: {start: 0, limit: membersStore.lastOptions.params.limit}});
          }
        }
      });
      
      // clear button for the filter field
      var clearButton = new Ext.Toolbar.Button({
        text: 'Clear',
        handler: function() {
          filterField.setValue("");
          membersStore.baseParams['q'] = "";
          membersStore.reload();
        }
      });

      var selectAllAction = new Ext.Action({
        text: "Select all",
        iconCls: "display_none"
      });

      var clearAllAction = new Ext.Action({
        text: "Clear all",
        iconCls: "display_none",
        disabled: true
      });
      
      var deleteAction = new Ext.Action({
        text: "Delete",
        iconCls: "display_none",
        disabled: true
      });
      
      var selectionMenu =  new Ext.menu.Menu({
        items: [selectAllAction, clearAllAction]
      });
      
      selectionMenu.addSeparator();
      selectionMenu.add(deleteAction);

      var gridTopToolbar = new Ext.Toolbar({
        cls: "top-toolbar",
        items: [{text:"&nbsp;&nbsp;&nbsp;Filter: "}, 
                filterBySelection,
                { text: ""},
                filterField, 
                clearButton, 
                { text: "Actions", menu: selectionMenu }]
      });
      
      var editRenderer = function(value, cell, record) {
        return '<div class="icon_pencilGo pointerOnHover"/>';
      };
      
      var membersCheckColumn = new Ext.grid.CheckColumn({
        dataIndex: 'checked',
        width: 30
      });
      
      membersCheckColumn.addListener("click", function(element, event, record){
        var params = {};
        params["party_id"] = record.get("id").split("_").last();
        var url = null;
        var method = null;
        if(record.get("checked")){
          url = #{join_group_path(@group).to_json};
          method = "POST";
          membersGrid.el.mask("Processing join group...");       
        }
        else{
          url = #{leave_group_path(@group).to_json};
          method = "DELETE";
          membersGrid.el.mask("Requesting to leave group...");
        }
        Ext.Ajax.request({
          url: url,
          params: params,
          method: method,
          success: function(response, options){
            membersGrid.el.unmask();
          }
        });
      });
      
      var membersGrid = new Ext.grid.GridPanel({
          store: membersStore,
          cm: new Ext.grid.ColumnModel([
              membersCheckColumn,
              {id: "members-display-name", width: 300, header: "Display Name", sortable: true, dataIndex: 'display-name'},
              {id: "members-email", width: 200, header: "Email", sortable: false, dataIndex: 'email-address'},
              {id: "members-phone", width: 200, header: "Phone", sortable: false, dataIndex: 'phone'},
              {id: "members-link", width: 200, header: "Website", sortable: false, dataIndex: 'link'}
            ]),
          autoScroll: true,
          width: "100%",
          tbar: gridTopToolbar, 
          bbar: paging,
          plugins: membersCheckColumn,
          selModel: new Ext.grid.RowSelectionModel,
          viewConfig: { autoFill: true },
          autoExpandColumn: "members-display-name",
          loadMask: true,
          height: #{get_default_grid_height(nil)}-30
      });
      
      xl.runningGrids.set("groups_edit_#{@group.id}", membersGrid);
      newPanel.on("destroy", function(){
        xl.runningGrids.unset("groups_edit_#{@group.id}");
      });
    `
  end

  def initialize_security_panel
    return "" unless @current_user_can_edit_party_security
    %Q`
      #{self.initialize_effective_permissions_grid_panel}
      #{self.initialize_selected_permissions_grid_panel}
      #{self.initialize_denied_permissions_grid_panel}
      #{self.initialize_roles_tree_panel}

      var securityPanel = new Ext.Panel({
        layout: "column",
        items: [
          {items: [effectivePermissionsGridPanel, selectPermissionsGridPanel], columnWidth: .5},
          {items: [rolesTreePanel, deniedPermissionsGridPanel], columnWidth: .5}
        ]
      });
    `
  end

  def initialize_effective_permissions_grid_panel
    %Q`
      var EffectivePermissionRecord = new Ext.data.Record.create([
        {name: 'id', mapping: 'id'},
        {name: 'name', mapping: 'name'}
      ]);

      var formattedEffectivePermissionsPath = #{formatted_effective_permissions_group_path(:id => @group.id, :format => "json").to_json};

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
            {id: "group-effective-permission-name", header: "Name", dataIndex: 'name'}
          ]),
        disableSelection: true,
        height: ((#{get_default_grid_height(nil)}-35)/2-1),
        autoExpandColumn: "group-effective-permission-name",
        frame: true,
        loadMask: true
      });

      xl.runningGrids.set("#{typed_dom_id(@group, :effective_permissions)}", effectivePermissionsGridPanel);
      newPanel.on("destroy", function(){
        xl.runningGrids.unset("#{typed_dom_id(@group, :effective_permissions)}");
      });
    `
  end

  def initialize_selected_permissions_grid_panel
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
            {id: "group-select-permission-name", header: "Name", dataIndex: 'name'}
          ]),
        height: ((#{get_default_grid_height(nil)}-35)/2-1),
        plugins: selectPermissionsCheckColumn,
        autoExpandColumn: "group-select-permission-name",
        frame: true
      });

      xl.runningGrids.set("#{typed_dom_id(@group, :select_permissions)}", selectPermissionsGridPanel);
      newPanel.on("destroy", function(){
        xl.runningGrids.unset("#{typed_dom_id(@group, :select_permissions)}");
      });
    `
  end

  def initialize_denied_permissions_grid_panel
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
            {id: "group-denied-permission-name", header: "Name", dataIndex: 'name'}
          ]),
        height: ((#{get_default_grid_height(nil)}-35)/2-1),
        plugins: deniedPermissionsCheckColumn,
        autoExpandColumn: "group-denied-permission-name",
        frame: true
      });

      xl.runningGrids.set("#{typed_dom_id(@group, :denied_permissions)}", deniedPermissionsGridPanel);
      newPanel.on("destroy", function(){
        xl.runningGrids.unset("#{typed_dom_id(@group, :denied_permissions)}");
      });
    `
  end

  def initialize_roles_tree_panel
    %Q`
      var rolesRootTreeNode =  new Ext.tree.AsyncTreeNode({
        text: "Role - Root",
        expanded: true,
        id: 0
      });

      var rolesTreePanel = new Ext.tree.TreePanel({
        title: "Roles",
        root: rolesRootTreeNode,
        rootVisible: false,
        frame: true,
        height: ((#{get_default_grid_height(nil)}-35)/2-1),
        loader: new Ext.tree.TreeLoader({
          requestMethod: "GET",
          url: #{formatted_roles_path(:group_id => @group.id, :format => :json).to_json},
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
                method: method,
                success: function(response, options){
                  effectivePermissionsDataStore.reload();
                }
              });
            },
            click: function(node, event){
              groupTreePermissionsConnection.url = #{@formatted_total_role_permission_grants_path.to_json}.sub("__ID__", node.id);
              groupTreePermissionsDataStore.reload();
            }
          }
      });
    `
  end
end
