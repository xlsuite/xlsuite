#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class CartLine < ActiveRecord::Base
  include XlSuite::InvoicableLine
  
  belongs_to :cart
  validates_presence_of :cart_id
  
  belongs_to :product

  acts_as_money :retail_price
  before_create :set_retail_price

  alias_method :total, :extension_price

  def to_liquid
    CartLineDrop.new(self)
  end
    
  protected
  
  def set_retail_price
    return if self.retail_price || self.product.blank?
    self.retail_price = self.product.retail_price
  end
end
