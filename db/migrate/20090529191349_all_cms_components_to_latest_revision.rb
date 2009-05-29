class AllCmsComponentsToLatestRevision < ActiveRecord::Migration
  def self.up
    latest_version = nil
    current_version = nil
  
    Page.all.each do |page|
      latest_version = page.versions.latest.version
      current_version = page.version
      if latest_version > current_version
        page.revert_to!(latest_version)
      elsif latest_version < current_version
        page.body = page.body + " "
        page.save
      end
    end
    
    Snippet.all.each do |snippet|
      latest_version = snippet.versions.latest.version
      current_version = snippet.version
      if latest_version > current_version
        snippet.revert_to!(latest_version)
      elsif latest_version < current_version
        snippet.body = snippet.body + " "
        snippet.save
      end
    end
    
    Layout.all.each do |layout|
      latest_version = layout.versions.latest.version
      current_version = layout.version
      if latest_version > current_version
        layout.revert_to!(latest_version)
      elsif latest_version < current_version
        layout.body = layout.body + " "
        layout.save
      end
    end
  end

  def self.down
  end
end
