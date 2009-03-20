class AddOpenHouseBooleanToListings < ActiveRecord::Migration
  def self.up
    add_column :listings, :open_house, :boolean, :default => false
  end

  def self.down
    remove_column :listings, :open_house
  end
end
