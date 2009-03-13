#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class InvoiceLine < ActiveRecord::Base
  belongs_to :account
  before_validation {|ol| ol.account = ol.invoice.order.account}
  validates_presence_of :account_id

  belongs_to :invoice
  belongs_to :product
  validates_presence_of :invoice_id, :if => Proc.new {|p| !p.new_record? }

  acts_as_list :scope => :invoice_id

  include XlSuite::InvoicableLine

  acts_as_reportable
  
  def to_liquid
    InvoiceLineDrop.new(self)
  end
end
