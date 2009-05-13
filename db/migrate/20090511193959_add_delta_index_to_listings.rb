class AddDeltaIndexToListings < ActiveRecord::Migration
  def self.up
    add_index :listings, :delta, :name => "by_delta"
  end

  def self.down
    remoev_index :listings, :name => "by_delta"
  end
end
