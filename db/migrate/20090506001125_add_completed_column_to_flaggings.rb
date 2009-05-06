class AddCompletedColumnToFlaggings < ActiveRecord::Migration
  def self.up
    add_column :flaggings, :completed, :boolean, :default => false
  end

  def self.down
    remove_column :flaggings, :completed
  end
end
