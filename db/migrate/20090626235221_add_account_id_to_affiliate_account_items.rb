class AddAccountIdToAffiliateAccountItems < ActiveRecord::Migration
  def self.up
    add_column :affiliate_account_items, :account_id, :integer
  end

  def self.down
    remove_column :affiliate_account_items, :account_id
  end
end
