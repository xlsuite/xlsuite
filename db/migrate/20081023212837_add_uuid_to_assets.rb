class AddUuidToAssets < ActiveRecord::Migration
  def self.up
    add_column :assets, :uuid, :string, :limit => 36
    Asset.update_all("uuid = UUID()")
  end

  def self.down
    remove_column :assets, :uuid
  end
  
  class Asset < ActiveRecord::Base; end
end
