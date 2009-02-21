class AddingNoUpdateToItemVersions < ActiveRecord::Migration
  def self.up
    add_column :item_versions, :no_update, :boolean, :default => false
  end

  def self.down
    remove_column :item_versions, :no_update
  end
  
  class ItemVersion < ActiveRecord::Base; end
end
