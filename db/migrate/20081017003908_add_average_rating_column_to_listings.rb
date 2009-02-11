class AddAverageRatingColumnToListings < ActiveRecord::Migration
  def self.up
    add_column :listings, :average_rating, :decimal, :precision => 5, :scale => 3, :default => 0, :null => false
  end

  def self.down
    remove_column :listings, :average_rating
  end
end
