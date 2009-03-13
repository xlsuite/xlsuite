#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class SortLine < ActiveRecord::Base
  belongs_to :search
  validates_uniqueness_of :priority, :scope => [:search_id]
  
  def to_hash
    hash = { :order_name => self.order_name, :order_mode => self.order_mode }
    return hash
  end
end
