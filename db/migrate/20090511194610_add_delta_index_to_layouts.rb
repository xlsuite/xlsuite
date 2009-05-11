class AddDeltaIndexToLayouts < ActiveRecord::Migration
  def self.up
    add_index :layouts, :delta, :name => "by_delta"
  end

  def self.down
    remove_index :layouts, :name => "by_delta"
  end
end
