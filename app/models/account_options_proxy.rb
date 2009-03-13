#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class AccountOptionsProxy
  attr_reader :account

  def initialize(account)
    @account = account
  end

  AccountModule::AVAILABLE_MODULES.each do |option_name|
    class_eval <<-EOF
      def #{option_name}=(value)
        self.account.#{option_name}_option = value
      end

      def #{option_name}?
        self.account.#{option_name}_option
      end
    EOF
  end
  
  def subscribed_modules
    options_attr = self.account.read_attribute(:options)
    return [] if options_attr && options_attr.kind_of?(Hash)
    options_attr.keys
  end
  
  def unsubscribed_modules
    AccountModule::AVAILABLE_MODULES - self.subscribed_modules
  end
end
