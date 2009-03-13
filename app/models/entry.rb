#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Entry < ActiveRecord::Base
  belongs_to :account
  belongs_to :feed
  
  validates_presence_of :account_id, :feed_id

  def to_liquid
    EntryDrop.new(self)
  end
end
