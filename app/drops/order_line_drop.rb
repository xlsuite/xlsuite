#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class OrderLineDrop < Liquid::Drop
  attr_reader :order_line
  delegate :description, :quantity, :quantity_shipped, :quantity_back_ordered, :retail_price, :product, :extension_price, :to => :order_line

  def initialize(order_line)
    @order_line = order_line
  end
end
