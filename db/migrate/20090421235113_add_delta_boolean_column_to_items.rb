class AddDeltaBooleanColumnToItems < ActiveRecord::Migration
  def self.up
    add_column :items, :delta, :boolean, :default => false
  end

  def self.down
    remove_column :items, :delta
  end
end
