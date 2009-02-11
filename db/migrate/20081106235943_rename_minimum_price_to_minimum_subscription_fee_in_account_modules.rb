class RenameMinimumPriceToMinimumSubscriptionFeeInAccountModules < ActiveRecord::Migration
  def self.up
    rename_column :account_modules, :minimum_price_cents, :minimum_subscription_fee_cents
    rename_column :account_modules, :minimum_price_currency, :minimum_subscription_fee_currency
  end

  def self.down
    rename_column :account_modules, :minimum_subscription_fee_cents, :minimum_price_cents
    rename_column :account_modules, :minimum_subscription_fee_currency, :minimum_price_currency
  end
end
