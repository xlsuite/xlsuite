#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class PaymentPlan < ActiveRecord::Base
  validates_presence_of :name
  
  def price
    Money.new(self.amount_in_cents)
  end
  
  def price=(amount)
    money = amount.to_money
    self.amount_in_cents = money.cents
  end
end
