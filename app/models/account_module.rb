#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class AccountModule < ActiveRecord::Base
  belongs_to :account
  validates_presence_of :account_id, :module
  
  AVAILABLE_MODULES = AccountTemplate::AVAILABLE_MODULES + %w(mass_mail rets_import site_import redirects)
  validates_inclusion_of :module, :in => AVAILABLE_MODULES
  validates_uniqueness_of :module, :scope => [:account_id]
  
  acts_as_money :minimum_subscription_fee
  
  def to_liquid
    AccountModuleDrop.new(self)
  end
  
  def self.free_modules
    #self.all(:select => :module, :conditions => ["minimum_subscription_fee_cents = 0 OR minimum_subscription_fee_cents IS NULL"]).map(&:module)
    %w(blogs forums product_catalog profiles)
  end
  
  def self.paying_modules
    AVAILABLE_MODULES.clone - self.free_modules
  end
  
  def self.count_minimum_subscription_fee(*args)
    fee = Money.zero
    args.flatten.each do |mod_name|
      fee += self.find_by_module(mod_name.to_s).minimum_subscription_fee
    end
    fee
  end
end
