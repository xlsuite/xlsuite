#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class OrderLine < ActiveRecord::Base
  belongs_to :account
  before_validation {|ol| ol.account = ol.order.account}
  validates_presence_of :account_id

  belongs_to :order
  belongs_to :product
  validates_presence_of :order_id

  acts_as_list :scope => :order_id
  acts_as_reportable
  
  include XlSuite::InvoicableLine
  
  before_create :copy_target_product_info
  before_save :check_if_retail_price_can_be_changed
  
  def to_liquid
    OrderLineDrop.new(self)
  end
  
  def dup
    attrs = self.attributes
    attrs.delete("id")
    OrderLine.new(attrs)
  end

  def target_id=(value)
    @target_id = value
  end
  
  def show?
    not self.quantity.zero?
  end
  
  def invoiced?
    not self.quantity_invoiced.zero?
  end
  
  def attach_expiring_items_to!(party, options={})
    return unless self.product
    self.product.attach_expiring_items_to!(party, options)
  end
  
  protected
  def check_if_retail_price_can_be_changed
    return true if self.new_record?
    old_self = self.class.find(self.id)
    if old_self.retail_price != self.retail_price
      not self.invoiced?
    else
      return true
    end
  end
  
  def copy_target_product_info
    return unless @target_id
    @target_id = returning(nil) do
      product_id = @target_id.split('_').last.to_i
      return if product_id == self.product_id
      
      # TODO: This bleeds... but I don't think it's going to pose any problem
      # Need to make this bleeds since it's needed for domain subscription stuff
      # The product of an order line inside a domain subscription's order does not 
      # necessarily belongs in the same account
      self.product = Product.find(product_id)
      self.sku = self.product.sku
      self.description = self.product.description
      self.retail_price = self.product.retail_price
      self.free_period = self.product.free_period
      self.pay_period = self.product.pay_period
      self.quantity = 1 if self.quantity.nil?
    end
  end
end
