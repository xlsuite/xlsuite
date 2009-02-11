class RenamingPeriodFeeInAccountTemplates < ActiveRecord::Migration
  def self.up
    rename_column :account_templates, :period_fee_cents, :subscription_markup_fee_cents
    rename_column :account_templates, :period_fee_currency, :subscription_markup_fee_currency
  end

  def self.down
    rename_column :account_templates, :subscription_markup_fee_cents, :period_fee_cents
    rename_column :account_templates, :subscription_markup_fee_currency, :period_fee_currency
  end
end
