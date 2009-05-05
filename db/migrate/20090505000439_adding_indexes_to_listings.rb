class AddingIndexesToListings < ActiveRecord::Migration
  def self.up
    add_index :listings, [:account_id, :public, :status], :name => "by_account_public_status"
  end

  def self.down
    remove_index :listings, :name => "by_account_public_status"
  end
end
