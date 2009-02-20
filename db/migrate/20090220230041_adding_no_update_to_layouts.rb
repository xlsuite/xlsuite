class AddingNoUpdateToLayouts < ActiveRecord::Migration
  def self.up
    add_column :layouts, :no_update, :boolean, :default => false
  end

  def self.down
    remove_column :layouts, :no_update
  end
end
