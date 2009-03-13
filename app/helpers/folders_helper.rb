#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module FoldersHelper

  def refresh_folder_datastore
    %Q` xl.runningGrids.each(function(pair){
        var grid = pair.value;
        var dataStore = grid.getStore();
        if (dataStore.proxy.conn.url.match(new RegExp('folders', 'i'))) {
          dataStore.reload();}});
      `
  end
  
  def folder_selections()
    options = [["*Root", ""]]
    current_account.folders.roots(:order => "name").reject{|root| !root.editable_by?(current_user)}.each do |root|
      options << [root.name, root.id]
      root.children(:order => "name").reject{|child| !child.editable_by?(current_user)}.each do |child|
        subfolder_marker = ""
        child.level.downto(1) { subfolder_marker << '-'}
        options << [subfolder_marker.concat(child.name), child.id]  
        options = child_selections(child, options) if !child.children.blank?
      end
    end
    options
  end
  
  def child_selections(folder, options)
    folder.children(:order => "name").reject{|child| !child.editable_by?(current_user)}.each do |child|
      subfolder_marker = ""
      child.level.downto(1) { subfolder_marker << '-'}
      options << [subfolder_marker.concat(child.name), child.id]
      options = child_selections(child, options) if !child.children.blank?
    end
    options
  end
  
  def expand_parents_of(selected_folders)
    out = []
    selected_folders.uniq.each do |selected_folder|
      out << "expandFolder('" + selected_folder.id.to_s +  "', true);"
      next if selected_folder.id == 0
      selected_folder.ancestors.each do |parent|
        out << "expandFolder('" + parent.id.to_s +  "', false);"
      end
    end
    out.join("")
  end
  
  def extjs_layout_setup
    javascript_tag %Q~
      Ext.onReady(function(){
        var westPanel = parent.xl.westPanel;
        
        westPanel.remove('westPanel-folders');
        
        westPanel.insert(0, {
          id: 'westPanel-folders',
          title: 'Directory',
          html: $("list-of-folders").innerHTML
        });
        
        westPanel.doLayout();
        
        var directoryAccordion = westPanel.findById("westPanel-folders")
        directoryAccordion.expand();
        
        var fileManagerTab = parent.xl.runningTabs["file-manager-index"];
        fileManagerTab.addListener("beforedestroy", function(){
          westPanel.remove('westPanel-folders');
          westPanel.doLayout();
        });
        
        fileManagerTab.addListener("show", function(){
          directoryAccordion.show();
          westPanel.doLayout();
          directoryAccordion.expand();
        })
        
        fileManagerTab.addListener("hide", function(){
          westPanel.findById("westPanel-folders").hide();
          westPanel.doLayout();
        });
      });
    ~
  end
end

