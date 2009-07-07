class AddingStatusToAffiliateAccounts < ActiveRecord::Migration
  def self.up
    add_column :affiliate_accounts, :status, :string, :limit => 15
  end

  def self.down
    remove_column :affiliate_accounts, :status
  end
end
