class AddNewColumnsToAffiliateAccountItemLines < ActiveRecord::Migration
  def self.up
    add_column :affiliate_account_item_lines, :subscription_period_length, :integer
    add_column :affiliate_account_item_lines, :subscription_period_unit, :string, :limit => 8
    add_column :affiliate_account_item_lines, :status, :string
    add_column :affiliate_account_item_lines, :subscription_started_at, :datetime
    add_column :affiliate_account_item_lines, :subscription_cancelled_at, :datetime
    add_column :affiliate_account_item_lines, :level, :integer
    remove_column :affiliate_account_item_lines, :subscription
  end

  def self.down
    remove_column :affiliate_account_item_lines, :subscription_period_length
    remove_column :affiliate_account_item_lines, :subscription_period_unit
    remove_column :affiliate_account_item_lines, :status
    remove_column :affiliate_account_item_lines, :subscription_started_at
    remove_column :affiliate_account_item_lines, :subscription_cancelled_at
    remove_column :affiliate_account_item_lines, :level
    add_column :affiliate_account_item_lines, :subscription, :boolean, :default => false
  end
end
