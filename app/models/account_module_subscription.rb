#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class AccountModuleSubscription < ActiveRecord::Base
  belongs_to :account
  validates_presence_of :account_id
  
  acts_as_money :minimum_subscription_fee

  has_one :payable, :as => :subject
  has_one :payment, :through => :payable
  
  has_one :installed_account_template

  serialize :options
  
  before_create :generate_random_uuid
  before_create :assign_next_number
  
  def installed_account_modules=(array)
    self.options[:installed_account_modules] = array
  end
  
  def installed_account_modules
    self.options[:installed_account_modules]
  end
  
  def options
    @options ||= returning(read_attribute(:options) || Hash.new) do |opts|
      write_attribute(:options, opts)
    end
  end
  
  def installed_account_template_name
    return "" unless self.installed_account_template
    self.installed_account_template.account_template.name
  end
  
  def status
    return "Error" unless self.payment
    self.payment.state
  end
  
  def subscription_fee
    fee = self.minimum_subscription_fee
    fee += self.installed_account_template.subscription_markup_fee if self.installed_account_template
    fee
  end
  
  def setup_fee
    return self.installed_account_template.setup_fee if self.installed_account_template
    Money.zero
  end
  
  def initial_fee
    self.setup_fee + self.subscription_fee
  end
  
  def self.find_next_number(account=nil)
    timestamp = Time.now.strftime("%Y%m%d%H%M%S").to_i
    maxno = self.maximum(:number, :conditions => ["LEFT(number, 14) = ?", timestamp])
    maxno ? maxno.succ : sprintf("%14d%04d", timestamp, 1)
  end
  
  def paid_in_full?
    return false unless self.status =~ /^paid$/i
    true
  end
  
  # Needed for the CustomerNotification
  def customer
    self.account.owner
  end
  
  protected
  def assign_next_number
    self.number = self.class.find_next_number(self.account)
  end  
end
