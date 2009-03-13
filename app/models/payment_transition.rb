#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class PaymentTransition < ActiveRecord::Base
  belongs_to :account
  validates_presence_of :account_id
  
  belongs_to :payment
  validates_presence_of :payment_id
  
  validates_presence_of :action, :to_state
  
  serialize :response_data
  serialize :ipn_request_headers
  serialize :ipn_request_parameters, Hash
  
  belongs_to :creator, :class_name => "Party", :foreign_key => "created_by_id"
  
  before_save :update_creator_name
  
  # credit_card being passed inside is assumed to be a valid credit card, please do the validation before calling this method
  def self.authorize(amount, credit_card, current_account, options={})
    options.merge!(:order_id => UUID.timestamp_create.to_s)
    process('authorization', current_account, amount) do |gw|
      gw.authorize(amount, credit_card, options)
    end
  end
  
  def self.capture(amount, authorization, current_account, options={})
    options.merge!(:order_id => UUID.timestamp_create.to_s)
    process('capture', current_account, amount) do |gw|
      gw.capture(amount, credit_card, options)
    end    
  end
  
  protected
  
  def update_creator_name
    return unless self.creator
    self.created_by_name = self.creator.name.to_s
  end
  
  def process(action, current_account, amount=nil)
    result = current_account.payment_transactions.build
    result.amount = amount.cents
    result.action = action
    begin
      response = yield gateway
      result.success = response.success?
      result.external_reference_number = response.authorization
      result.response_message = response.message
      result.response_data = response.params
    rescue ActiveMerchant::ActiveMerchantError => e
      result.success = false
      result.external_reference_number = nil
      result.response_message = e.message
      result.response_data = {}
    end
    result
  end
end
