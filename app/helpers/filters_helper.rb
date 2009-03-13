#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module FiltersHelper
  def filter_field_selections(selected="from")
    options_for_select([["From", "from"], ["To", "to"], ["Subject", "subject"], ["Body", "body"]], selected)
  end
  
  def filter_operator_selections(selected="eq")
    options_for_select([["Equals", "eq"], ["Starts with", "start"], ["Contains", "contain"], ["Ends with", "end"]], selected)
  end
  
  def email_labels_selections(selected=nil)
    options = [["", nil]]
    current_user.email_labels.each {|label| options << [label.name, label.id]}
    options_for_select(options << ["New Label...", "new_label"], selected)
  end
  
  def render_extjs_filter_grid
    limit = 20
    javascript_tag %Q`
      Ext.onReady(function(){
        var connection = new Ext.data.Connection({url: '/admin/filters/empty_grid', method: 'get'});
        var reader = new Ext.data.JsonReader({totalProperty: "total", root: "collection", id: "id"}, parent.xl.email.truncatedRecord);
        store = new Ext.data.Store({
          proxy: new Ext.data.HttpProxy(connection),
          reader: reader,
          remoteSort: true,
          baseParams: {q: ''},
          id: 'filter_store'
        });
           
        store.load({params: {start: 0, limit: #{limit} }});
        var paginator = new Ext.PagingToolbar({
          store: store,
          pageSize: #{limit},
          displayInfo: true,
          displayMsg: 'Displaying {0} to {1} of {2}',
          emptyMsg: "No emails to display",
          cls: "paging-toolbar-bottom",
          plugins: [new Ext.ux.PageSizePlugin]
        });
        var grid = new Ext.grid.GridPanel({
          store: store,
          columns: [
            {header: 'From', width: 120, sortable: false, dataIndex: 'sender_name'},
            {header: 'To', width: 90, sortable: false, dataIndex: 'to_names'},
            {header: 'Subject', width: 90, sortable: false, dataIndex: 'subject'},
            {header: 'Body', width: 90, sortable: false, dataIndex: 'body'}
          ],
          viewConfig: {
            forceFit: true
          },
          renderTo: 'email_list',
          id: 'filtered_email_grid',
          height: 320, 
          autoWidth: true,
          autoShow: true,
          bbar: [paginator],
          tbar: ["Filtering results"]
        });
        grid.getTopToolbar().addClass("top-toolbar");
        grid.getBottomToolbar().addClass("bottom-toolbar");
        grid.emailGridHeight = 370;
        parent.xl.runningGrids.set("filtersTestGrid", grid);
      });
    `
  end
end
