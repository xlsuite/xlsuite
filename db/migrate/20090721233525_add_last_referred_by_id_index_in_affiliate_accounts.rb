class AddLastReferredByIdIndexInAffiliateAccounts < ActiveRecord::Migration
  def self.up
    add_index :affiliate_accounts, [:last_referred_by_id], :name => "by_last_referred_by"
  end

  def self.down
    remove_index :affiliate_accounts, :name => "by_last_referred_by"
  end
end
