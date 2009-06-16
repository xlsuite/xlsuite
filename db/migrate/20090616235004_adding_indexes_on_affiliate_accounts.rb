class AddingIndexesOnAffiliateAccounts < ActiveRecord::Migration
  def self.up
    add_index :affiliate_accounts, :username, :name => "by_username"
    add_index :affiliate_accounts, :email_address, :name => "by_email_address"
  end

  def self.down
    remove_index :affiliate_accounts, :name => "by_username"
    remove_index :affiliate_accounts, :name => "by_email_address"
  end
end
