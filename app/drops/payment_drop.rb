#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class PaymentDrop < Liquid::Drop
  attr_reader :payment
  delegate :id, :amount, :ever_failed, :created_at, :updated_at, :payment_method, 
      :description, :state, :quick_description, :to => :payment

  def initialize(payment)
    @payment = payment
  end
  
end
