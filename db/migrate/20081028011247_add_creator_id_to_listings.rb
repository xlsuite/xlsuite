class AddCreatorIdToListings < ActiveRecord::Migration
  def self.up
    add_column :listings, :creator_id, :integer
  end

  def self.down
    remove_column :listings, :creator_id
  end
end
