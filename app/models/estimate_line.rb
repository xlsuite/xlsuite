#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class EstimateLine < ActiveRecord::Base
  belongs_to :account
  before_validation {|ol| ol.account = ol.estimate.account}
  validates_presence_of :account_id

  belongs_to :estimate
  belongs_to :product
  validates_presence_of :estimate_id

  acts_as_list :scope => :estimate_id

  include XlSuite::InvoicableLine
  
  def to_liquid
    EstimateLineDrop.new(self)
  end
  
  def dup
    attrs = self.attributes
    attrs.delete("id")
    EstimateLine.new(attrs)
  end

  def target_id=(value)
    product_id = value.split('_').last
    return if self.product_id.to_i == product_id.to_i
    self.product = self.account.products.find(product_id)
    self.sku = self.product.sku
    self.description = self.product.description
    self.retail_price = self.product.retail_price
    self.free_period = self.product.free_period
    self.pay_period = self.product.pay_period
    self.quantity = 1 if self.quantity.nil?
  end
  
  def show?
    not self.quantity.zero?
  end
end
