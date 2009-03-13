#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class DomainSubscription < ActiveRecord::Base
  belongs_to :account
  # the account of the order is not going to be same as self.account: it'll be the account's parent account!
  belongs_to :order
  
  # self.paypal_subscription_id is the number Paypal sends us through IPN
  # after a payment of a domain subscription has been confirmed
  validates_uniqueness_of :paypal_subscription_id, :scope => :account_id, :if => Proc.new {|e| !e.paypal_subscription_id.blank?}
  
  # the value of self.amount will be copied from a product's retail_price or wholesale_price
  acts_as_money :amount
  # the value of self.free_period and self.pay_period will be copied from the product
  acts_as_period :free_period, :pay_period, :allow_nil => true
  
  has_many :domains
  
  after_save :activate_or_cancel_related_domains
  
  def status
    return "Cancelled" if self.cancelled_at
    return "Free" if self.order.nil?
    return "Paid" if self.paypal_subscription_id
    self.order.status.blank? ? "Pending" : self.order.status
  end
  
  protected
  
  def activate_or_cancel_related_domains
    if self.status =~ /paid/i
      Domain.update_all(["activated_at = ?", Time.now.utc], 
        ["activated_at IS NULL AND account_id = ? AND domain_subscription_id = ?", self.account_id, self.id])
    else
      Domain.update_all("activated_at = NULL", 
        ["account_id = ? AND domain_subscription_id = ?", self.account_id, self.id])
    end
  end
end
