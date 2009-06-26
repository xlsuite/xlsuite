class RenamingCommissionRelatedColumnsInAffiliateAccountItemLines < ActiveRecord::Migration
  def self.up
    rename_column :affiliate_account_item_lines, :commission_cents, :commission_amount_cents
    rename_column :affiliate_account_item_lines, :commission_currency, :commission_amount_currency
  end

  def self.down
    rename_column :affiliate_account_item_lines, :commission_amount_cents, :commission_cents
    rename_column :affiliate_account_item_lines, :commission_amount_currency, :commission_currency
  end
end
