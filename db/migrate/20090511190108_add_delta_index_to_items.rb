class AddDeltaIndexToItems < ActiveRecord::Migration
  def self.up
    add_index :items, :delta, :name => "by_delta"
  end

  def self.down
    remove_index :items, :name => "by_delta"
  end
end
