#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class AccountModuleDrop < Liquid::Drop
  delegate :module, :minimum_subscription_fee, :to => :account_module
  attr_reader :account_module

  def initialize(account_module=nil)
    @account_module = account_module
  end
  
  alias_method :name, :module
  
  def minimum_subscription_fee
    MoneyDrop.new(self.account_module.minimum_subscription_fee)
  end
  alias_method :fee, :minimum_subscription_fee
end
