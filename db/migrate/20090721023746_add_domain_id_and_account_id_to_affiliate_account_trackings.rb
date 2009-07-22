class AddDomainIdAndAccountIdToAffiliateAccountTrackings < ActiveRecord::Migration
  def self.up
    add_column :affiliate_account_trackings, :domain_id, :integer
    add_column :affiliate_account_trackings, :account_id, :integer
  end

  def self.down
    remove_column :affiliate_account_trackings, :domain_id
    remove_column :affiliate_account_trackings, :account_id
  end
end
