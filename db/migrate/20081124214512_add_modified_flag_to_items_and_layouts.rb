class AddModifiedFlagToItemsAndLayouts < ActiveRecord::Migration
  def self.up
    add_column :items, :modified, :boolean
    add_column :item_versions, :modified, :boolean
    add_column :layouts, :modified, :boolean
    add_column :layout_versions, :modified, :boolean
  end

  def self.down
    remove_column :items, :modified
    remove_column :item_versions, :modified
    remove_column :layouts, :modified
    remove_column :layout_versions, :modified
  end
end
