#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class CartLineDrop < Liquid::Drop
  attr_reader :cart_line
  delegate :id, :description, :quantity, :product, :retail_price, :cart, :extension_price, :to => :cart_line

  def initialize(cart_line)
    @cart_line = cart_line
  end
  
  def total
    self.extension_price
  end
end
