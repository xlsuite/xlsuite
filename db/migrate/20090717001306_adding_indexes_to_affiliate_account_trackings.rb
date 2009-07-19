class AddingIndexesToAffiliateAccountTrackings < ActiveRecord::Migration
  def self.up
    add_index :affiliate_account_trackings, [:affiliate_account_id], :name => "by_affiliate_account"
    add_index :affiliate_account_trackings, [:affiliate_account_id, :created_at], :name => "by_affiliate_account_created_at"
  end

  def self.down
    remove_index :affiliate_account_trackings, :name => "by_affiliate_account"
    remove_index :affiliate_account_trackings, :name => "by_affiliate_account_created_at"
  end
end
