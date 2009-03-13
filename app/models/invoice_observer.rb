#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class InvoiceObserver < ActiveRecord::Observer  
  def before_save(invoice)
    if invoice.new_record? then
      invoice.status = "New"
    elsif invoice.balance.zero? then
      invoice.paid_in_full = true
      invoice.status = "Collected"
    end
  end
end
