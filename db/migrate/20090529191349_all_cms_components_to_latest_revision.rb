class AllCmsComponentsToLatestRevision < ActiveRecord::Migration
  def self.up
    latest_version = nil
    current_version = nil
  
    account_ids = Account.all(:select => "id").map(&:id)
    account_ids = account_ids.reject(&:blank?)
    
    account_ids.each do |account_id|
      Page.all(:conditions => {:account_id => account_id}).each do |page|
        latest_version = page.versions.latest
        next unless latest_version
        latest_version = latest_version.version
        current_version = page.version
        if latest_version > current_version
          page.revert_to!(latest_version)
        elsif latest_version < current_version
          page.body = page.body + " "
          page.save
        end
      end
      
      Snippet.all(:conditions => {:account_id => account_id}).each do |snippet|
        latest_version = snippet.versions.latest
        next unless latest_version
        latest_version = latest_version.version
        current_version = snippet.version
        if latest_version > current_version
          snippet.revert_to!(latest_version)
        elsif latest_version < current_version
          snippet.body = snippet.body + " "
          snippet.save
        end
      end
      
      Layout.all(:conditions => {:account_id => account_id}).each do |layout|
        latest_version = layout.versions.latest
        next unless latest_version
        latest_version = latest_version.version
        current_version = layout.version
        if latest_version > current_version
          layout.revert_to!(latest_version)
        elsif latest_version < current_version
          layout.body = layout.body + " "
          layout.save
        end
      end
    end
  end

  def self.down
  end
end
