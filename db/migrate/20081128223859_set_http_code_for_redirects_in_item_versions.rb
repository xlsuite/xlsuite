class SetHttpCodeForRedirectsInItemVersions < ActiveRecord::Migration
  def self.up
    ItemVersion.update_all("http_code=307","versioned_type='Redirect'")
  end

  def self.down
    ItemVersion.update_all("http_code=200","versioned_type='Redirect'")
  end
  
  class ItemVersion < ActiveRecord::Base; end
end
