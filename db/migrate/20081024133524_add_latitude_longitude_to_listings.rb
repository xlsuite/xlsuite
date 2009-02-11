class AddLatitudeLongitudeToListings < ActiveRecord::Migration
  def self.up
    add_column :listings, :latitude, :float
    add_column :listings, :longitude, :float
  end

  def self.down
    remove_column :listings, :latitude
    remove_column :listings, :longitude
  end
end
