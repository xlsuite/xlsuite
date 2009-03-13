#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module BlogsHelper
  def set_active_tab
    out = %Q`
      tabPanel.setActiveTab(#{self.generate_inside_tab_panel_id(:posts).to_json});
    `
    return out if params[:open] =~ /posts/i
    ""
  end
  
  def initialize_groups_access_panel
    %Q`
      var groupsRootTreeNode =  new Ext.tree.AsyncTreeNode({
        text: "Group - Root",
        expanded: true,
        id: 0
      });

      var groupsReadAccessSelections = new Array();
      
      var groupsFileTreePanel = new Ext.tree.TreePanel({
        title: "Groups Read Access",
        root: groupsRootTreeNode,
        rootVisible: false,
        loader: new Ext.tree.TreeLoader({
          requestMethod: "GET",
          url: #{formatted_read_access_groups_blog_path(:id => @blog.id, :format => :json).to_json},
          baseAttrs: {uiProvider: Ext.tree.TreeCheckNodeUI},
          listeners: {
            load: function(treeLoader, node, response){
              groupsReadAccessSelections = groupsFileTreePanel.getChecked("id");
            }
          }
        }),
        listeners: {
            check: function(node, checked){
              var params = {};
              if(checked){
                groupsReadAccessSelections.push(node.id);
              }
              else{
                var nodeIndex = groupsReadAccessSelections.indexOf(node.id)
                if (nodeIndex != -1) {
                  groupsReadAccessSelections.splice(nodeIndex, 1);
                }
              }
              params["blog[reader_ids]"] = groupsReadAccessSelections.join(",");
              Ext.Ajax.request({
                url: #{blog_path(@blog).to_json},
                params: params,
                method: "PUT",
                success: function(response, options){
                }
              });
            }
          }
      });
    `
  end  
end
