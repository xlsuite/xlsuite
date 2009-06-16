class AddingIndexesOnAffiliateAccountItems < ActiveRecord::Migration
  def self.up
    add_index :affiliate_account_items, :affiliate_account_id, :name => "by_affiliate_account"
    add_index :affiliate_account_items, [:target_type, :target_id], :name => "by_target"
  end

  def self.down
    remove_index :affiliate_account_items, :name => "by_affiliate_account"
    remove_index :affiliate_account_items, :name => "by_target"
  end
end
