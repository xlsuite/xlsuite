class AddingNoUpdateToItems < ActiveRecord::Migration
  def self.up
    add_column :items, :no_update, :boolean, :default => false
  end

  def self.down
    remove_column :items, :no_update
  end
end
