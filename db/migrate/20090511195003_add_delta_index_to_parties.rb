class AddDeltaIndexToParties < ActiveRecord::Migration
  def self.up
    add_index :parties, :delta, :name => "by_delta"
  end

  def self.down
    remove_index :parties, :name => "by_delta"
  end
end
