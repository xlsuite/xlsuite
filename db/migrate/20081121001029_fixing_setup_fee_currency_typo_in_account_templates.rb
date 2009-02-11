class FixingSetupFeeCurrencyTypoInAccountTemplates < ActiveRecord::Migration
  def self.up
    rename_column :account_templates, :setup_fee_currencey, :setup_fee_currency
    AccountTemplate.update_all("setup_fee_currency='CAD'", "setup_fee_currency IS NULL")
  end

  def self.down
  end
end
