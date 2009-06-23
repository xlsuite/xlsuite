class AddingPercentageToAffiliateAccountItems < ActiveRecord::Migration
  def self.up
    add_column :affiliate_account_items, :percentage, :decimal, :precision => 5, :scale => 2
  end

  def self.down
    remove_column :affiliate_account_items, :percentage
  end
end
