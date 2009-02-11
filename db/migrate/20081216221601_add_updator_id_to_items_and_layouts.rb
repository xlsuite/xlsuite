class AddUpdatorIdToItemsAndLayouts < ActiveRecord::Migration
  def self.up
    add_column :items, :updator_id, :integer
    add_column :layouts, :updator_id, :integer
    add_column :item_versions, :updator_id, :integer
    add_column :layout_versions, :updator_id, :integer
  end

  def self.down
    remove_column :items, :updator_id
    remove_column :layouts, :updator_id
    remove_column :item_versions, :updator_id
    remove_column :layout_versions, :updator_id
  end
end
