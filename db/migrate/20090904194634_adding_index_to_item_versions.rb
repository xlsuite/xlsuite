class AddingIndexToItemVersions < ActiveRecord::Migration
  def self.up
    add_index :item_versions, [:item_id, :version], :name => "by_item_version"
  end

  def self.down
    remove_index :item_versions, :name => "by_item_version"
  end
end
