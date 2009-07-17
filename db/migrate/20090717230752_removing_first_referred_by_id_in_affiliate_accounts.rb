class RemovingFirstReferredByIdInAffiliateAccounts < ActiveRecord::Migration
  def self.up
    remove_column :affiliate_accounts, :first_referred_by_id 
  end

  def self.down
    add_column :affiliate_accounts, :first_referred_by_id, :integer
  end
end
