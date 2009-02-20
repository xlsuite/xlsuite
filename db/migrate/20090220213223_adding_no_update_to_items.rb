class AddingNoUpdateToItems < ActiveRecord::Migration
  def self.up
    add_column :items, :no_update, :boolean
  end

  def self.down
    remove_column :items, :no_update
  end
end
