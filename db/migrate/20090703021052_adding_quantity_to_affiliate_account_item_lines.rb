class AddingQuantityToAffiliateAccountItemLines < ActiveRecord::Migration
  def self.up
    add_column :affiliate_account_item_lines, :quantity, :decimal, :precision => 12, :scale => 4, :default => 0
  end

  def self.down
    remove_column :affiliate_account_item_lines, :quantity
  end
end
