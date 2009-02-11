class FixingNilSetupFeeCurrencyInInstalledAccountTemplates < ActiveRecord::Migration
  def self.up
    InstalledAccountTemplate.update_all("setup_fee_currency = 'CAD'", "setup_fee_currency IS NULL AND setup_fee_cents IS NOT NULL")
  end

  def self.down
  end
end
