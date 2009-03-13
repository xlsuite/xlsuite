#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Subscription < ActiveRecord::Base
  belongs_to :account
  validates_presence_of :account_id
  
  belongs_to :payer, :class_name => "Party"
  validates_presence_of :payer_id
  
  belongs_to :subject, :polymorphic => true
  validates_presence_of :subject_type, :subject_id
  
  validates_presence_of :authorization_code
  
  acts_as_period :renewal_period
  validates_presence_of :next_renewal_at, :renewal_period_unit, :renewal_period_length
  
  validates_inclusion_of :payment_method, :in => Payment::ValidPaymentMethods
  
  def pay!
    if self.payment_method == "paypal"
      self.update_next_renewal_at
      return true
    end
    return false unless self.next_renewal_at < Time.now.utc
    payment, payable = nil, nil
    ActiveRecord::Base.transaction do
      case self.subject
      when AccountModuleSubscription
        master_account = Account.find_by_master(true)
        payment_amount = self.subject.subscription_fee
        payment = master_account.payments.create!(:amount => payment_amount, 
          :payment_method => self.payment_method,
          :description => "Payment for account subscription of #{self.subject.account.domains.first.name} on #{self.next_renewal_at.strftime(DATE_STRFTIME_FORMAT)}",
          :payer => self.payer
        )
        payable = master_account.payables.create!(:payment => payment, :amount => payment_amount, :subject => self)
      when Order
        payment_amount = self.subject.total_amount
        payment = self.account.payments.create!(:amount => payment_amount, 
          :payment_method => self.payment_method,
          :description => "Payment for order #{self.subject.number} subscription on #{self.next_renewal_at.strftime(DATE_STRFTIME_FORMAT)}",
          :payer => self.payer
        )
        payable = self.account.payables.create!(:payment => payment, :amount => payment_amount, :subject => self)
      else
        raise StandardError, "Subscription subject not supported"
      end
    end
    self.update_next_renewal_at
    payment.start!(self.payer)
  end
  
  def paid_in_full?
    false
  end
  
  def customer
    self.payer
  end
  
  def update_next_renewal_at
    self.update_attribute(:next_renewal_at, (self.next_renewal_at + self.renewal_period_length.send(self.renewal_period_unit).to_i) )
  end
end
