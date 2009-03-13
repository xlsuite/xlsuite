#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class CartItem
  attr_reader :retail_price, :product, :description
  attr_accessor :quantity

  def initialize(options={})
    @product = options[:product]
    @quantity = options[:quantity]
    @retail_price = options[:retail_price] || @product.current_price(Time.now)
    @description = options[:description] || options[:product].name
  end

  def extension_price
    self.retail_price * self.quantity
  end

  def no
    self.product.product_no
  end

  def comment?; false; end
  def manhours?; false; end
  def cursor?; false; end
end
