class InitializeAccountOptionsWithFreeModules < ActiveRecord::Migration
  def self.up
    Account.all.each do |account|
      account.options = (account.options || {}).merge({:blogs => true, :forums => true, :product_catalog => true, :profiles => true})
      account.save
    end
  end

  def self.down
    Account.all.each do |account|
      account.options = (account.options || {}).merge({:blogs => false, :forums => false, :product_catalog => false, :profiles => false})
    end
  end
  
  class Account < ActiveRecord::Base
    serialize :options
  end
end
