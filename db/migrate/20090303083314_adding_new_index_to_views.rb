class AddingNewIndexToViews < ActiveRecord::Migration
  def self.up
    add_index :views, [:asset_id, :attachable_type, :attachable_id], :name => "by_asset_attachable"
  end

  def self.down
    remove_index :views, :name => "by_asset_attachable"
  end
end
