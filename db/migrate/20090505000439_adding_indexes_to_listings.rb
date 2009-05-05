class AddingIndexesToListings < ActiveRecord::Migration
  def self.up
    add_index :listings, [:account_id, :public, :status], :name => "by_account_public_status"
    add_index :listings, [:account_id, :public, :open_house], :name => "by_account_public_open_house"
  end

  def self.down
    remove_index :listings, :name => "by_account_public_status"
    remove_index :listings, :name => "by_account_public_open_house"
  end
end
