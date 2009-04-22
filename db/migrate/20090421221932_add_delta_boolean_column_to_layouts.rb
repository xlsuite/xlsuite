class AddDeltaBooleanColumnToLayouts < ActiveRecord::Migration
  def self.up
    add_column :layouts, :delta, :boolean, :default => false
  end

  def self.down
    remove_column :layouts, :delta
  end
end
