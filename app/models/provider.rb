#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Provider < ActiveRecord::Base
  belongs_to :account  
  belongs_to :supplier
  belongs_to :product
  
  validates_presence_of :account_id, :supplier_id, :product_id, :sku
  validates_uniqueness_of :supplier_id, :scope => :product_id
  
  acts_as_money :wholesale_price
end
