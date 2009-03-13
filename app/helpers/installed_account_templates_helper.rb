#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module InstalledAccountTemplatesHelper
  def generate_no_update_items_grid
    no_update_items_path_json = formatted_no_update_items_installed_account_template_path(:id => @installed_account_template.id, :format => :json).to_json
    %Q`
      var NoUpdateItemRecord = new Ext.data.Record.create([
        {name: 'id', mapping: 'id'},
        {name: 'type', mapping: 'type'},
        {name: 'identifier', mapping: 'identifier'},
        {name: 'domain_patterns', mapping: 'domain_patterns'},
        {name: 'updated_at', mapping: 'updated_at'}
      ]);
      var reader = new Ext.data.JsonReader({totalProperty: "total", root: "collection", id: "id"}, NoUpdateItemRecord);
      var connection = new Ext.data.Connection({url: #{no_update_items_path_json}, method: 'get'});
      var proxy = new Ext.data.HttpProxy(connection);
      var noUpdateItemsStore = new Ext.data.Store({proxy: proxy, reader: reader, remoteSort: true, baseParams: {q: ''}});

      var noUpdateToTextButton = new Ext.Toolbar.Button({
        text: "To TEXT",
        handler: function(btn, e){
          var text = "";
          var gridColumnDataIndex = new Array();
          var gridColumnModel = noUpdateItemsGrid.getColumnModel();
          for(var i=0; i<gridColumnModel.getColumnCount(); i++){
            gridColumnDataIndex.push(gridColumnModel.getDataIndex(i));
          }
          noUpdateItemsStore.each(function(record){
            var content = new Array();
            gridColumnDataIndex.forEach(function(element, index, array){
              content.push(record.get(element));
            });
            text += (content.join(", ") + "\\n");
          });

          var gridToText = new Ext.form.TextArea({
            value: text,
            readOnly: true,
            listeners: {
              render: function(cpt){
                xl.fitToOwnerCt(cpt);
              }
            }
          });

          var win = new Ext.Window({
            title: noUpdateItemsGrid.title,
            items: gridToText,
            height: 400,
            width: 300,
            autoScroll: true,
            listeners: {
              resize: function(cpt){
                xl.fitToOwnerCt(gridToText);
              }
            }
          });
          win.show();
        }
      });

      var noUpdateItemsGrid = new Ext.grid.GridPanel({
        title: "Do not update CMS component(s)",
        store: noUpdateItemsStore,
        cm: new Ext.grid.ColumnModel([
            {id: "type", header: "Type", width: 75, dataIndex: 'type'},
            {id: "identifier", header: "Identifier", dataIndex: 'identifier'},
            {id: "domain_patterns", header: "Domain Pattern", dataIndex: 'domain_patterns'},
            {id: "updated_at", width: 125, header: "Updated at", dataIndex: 'updated_at'}
          ]),
        bbar: [noUpdateToTextButton],
        listeners: {
          render: function(cpt){
            noUpdateItemsStore.load();
            xl.fitToOwnerCt(cpt);
          }
        }
      });
    `
  end

  def generate_changed_items_grid
    changed_items_path_json = formatted_changed_items_installed_account_template_path(:id => @installed_account_template.id, :format => :json).to_json
    %Q`
      var excludeItemIds = new Array();

      var ChangedItemRecord = new Ext.data.Record.create([
        {name: 'id', mapping: 'id'},
        {name: 'type', mapping: 'type'},
        {name: 'identifier', mapping: 'identifier'},
        {name: 'domain_patterns', mapping: 'domain_patterns'},
        {name: 'updated_at', mapping: 'updated_at'},
        {name: 'include', mapping: 'include'}
      ]);
      var reader = new Ext.data.JsonReader({totalProperty: "total", root: "collection", id: "id"}, ChangedItemRecord);
      var connection = new Ext.data.Connection({url: #{changed_items_path_json}, method: 'get'});
      var proxy = new Ext.data.HttpProxy(connection);
      var changedItemsStore = new Ext.data.Store({proxy: proxy, reader: reader, remoteSort: true, baseParams: {q: ''}});

      var toTextButton = new Ext.Toolbar.Button({
        text: "To TEXT",
        handler: function(btn, e){
          var text = "";
          var gridColumnDataIndex = new Array();
          var gridColumnModel = changedItemsGrid.getColumnModel();
          for(var i=0; i<gridColumnModel.getColumnCount(); i++){
            gridColumnDataIndex.push(gridColumnModel.getDataIndex(i));
          }
          changedItemsStore.each(function(record){
            var content = new Array();
            gridColumnDataIndex.forEach(function(element, index, array){
              content.push(record.get(element));
            });
            text += (content.join(", ") + "\\n");
          });

          var gridToText = new Ext.form.TextArea({
            value: text,
            readOnly: true,
            listeners: {
              render: function(cpt){
                xl.fitToOwnerCt(cpt);
              }
            }
          });

          var win = new Ext.Window({
            title: changedItemsGrid.title,
            items: gridToText,
            height: 400,
            width: 300,
            autoScroll: true,
            listeners: {
              resize: function(cpt){
                xl.fitToOwnerCt(gridToText);
              }
            }
          });
          win.show();
        }
      });

      var cmsComponentCheckColumn = new Ext.grid.CheckColumn({
        id: 'include',
        header: "Include",
        dataIndex: "include",
        width: 45
      });

      cmsComponentCheckColumn.addListener("click", function(element, event, record){
        var objectId = record.get("id");
        if(!record.get("include"))
          excludeItemIds.push(objectId);
        else
          excludeItemIds.remove(objectId);
      });

      var changedItemsGrid = new Ext.grid.GridPanel({
        title: "Modified CMS component(s) to be replaced",
        store: changedItemsStore,
        cm: new Ext.grid.ColumnModel([
            cmsComponentCheckColumn,
            {id: "type", header: "Type", width: 75, dataIndex: 'type'},
            {id: "identifier", header: "Identifier", dataIndex: 'identifier'},
            {id: "domain_patterns", header: "Domain Pattern", dataIndex: 'domain_patterns'},
            {id: "updated_at", width: 125, header: "Updated at", dataIndex: 'updated_at'}
          ]),
        bbar: [toTextButton],
        plugins: cmsComponentCheckColumn,
        listeners: {
          render: function(cpt){
            changedItemsStore.load();
            xl.fitToOwnerCt(cpt);
          }
        }
      });
    `
  end
end
