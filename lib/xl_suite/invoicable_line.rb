#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  module InvoicableLine
    def self.included(base)
      base.validates_numericality_of :quantity, :retail_price_cents, :allow_nil => true
      base.composed_of :retail_amount, :class_name => "Money", :mapping => [%w(retail_price_cents cents), %w(retail_price_currency currency)], :allow_nil => true
      base.before_create :copy_product_info_over
      base.acts_as_list :scope => base.name.underscore.sub("_line", "").to_sym
      base.acts_as_period :free_period, :pay_period, :allow_nil => true
    end

    # Needed only for Product lines
    def copy_product_info_over
      return unless self.respond_to?(:product)
      return unless self.product
      self.sku = self.product.sku if self.sku.blank?
      self.description = self.product.description if self.description.blank?
      self.retail_price = self.product.retail_price if self.retail_price.blank? || self.retail_price.zero?
    end
    protected :copy_product_info_over

    def retail_price
      self.retail_amount
    end

    def retail_price=(value)
      case value
      when NilClass
        self.retail_amount = nil
      when Money
        self.retail_amount = value
      when String
        self.retail_amount = value.blank? ? nil : value.to_money
      else
        raise ArgumentError, "#retail_price= expects nil, a Money instance, or a String of the form '15.00 CAD'"
      end
    end

    def extension_price
      return Money.zero(retail_price ? retail_price.currency : Money.default_currency) unless (retail_price && quantity)
      retail_price * quantity
    end

    def quantity_back_ordered
      quantity - quantity_shipped
    end
    
    def main_identifier
      return self.description unless self.product
      return self.product.name unless self.product.name.blank?
      return self.product.description
    end

    alias_method :quantity_bo, :quantity_back_ordered
  end
end
