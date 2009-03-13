#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class InvoiceLineDrop < Liquid::Drop
  attr_reader :invoice_line
  delegate :description, :quantity, :quantity_shipped, :quantity_back_ordered, :retail_price, :product, :extension_price, :to => :invoice_line

  def initialize(invoice_line)
    @invoice_line = invoice_line
  end
end
