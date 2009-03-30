class AddPointAddedInComments < ActiveRecord::Migration
  def self.up
    add_column :comments, :point_added, :boolean, :default => false
  end

  def self.down
    remove_column :comments, :point_added
  end
end
