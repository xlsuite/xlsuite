class ChangingRetsToRetsImportInOptionsColumnOfAccountsTable < ActiveRecord::Migration
  def self.up
    Account.all(:conditions => "options IS NOT NULL").each do |account|
      if account.options.has_key?(:rets)
        account.options[:rets_import] = account.options.delete(:rets)
        account.save
      end
    end
  end

  def self.down
    Account.all(:conditions => "options IS NOT NULL").each do |account|
      if account.options.has_key?(:rets_import)
        account.options[:rets] = account.options.delete(:rets_import)
        account.save
      end
    end
  end
  
  class Account < ActiveRecord::Base
    serialize :options
  end
end
