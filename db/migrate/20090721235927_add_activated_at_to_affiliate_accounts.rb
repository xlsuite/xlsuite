class AddActivatedAtToAffiliateAccounts < ActiveRecord::Migration
  def self.up
    add_column :affiliate_accounts, :activated_at, :datetime
  end

  def self.down
    remove_column :affiliate_accounts, :activated_at
  end
end
