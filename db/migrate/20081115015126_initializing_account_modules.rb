class InitializingAccountModules < ActiveRecord::Migration
  def self.up
    master_acct = Account.find_by_master(true)
    return unless master_acct
    AccountModule::AVAILABLE_MODULES.each do |module_name|
      AccountModule.create!(:account => master_acct, :module => module_name, :minimum_subscription_fee => Money.zero)
    end
  end

  def self.down
    AccountModule.delete_all
  end
end
