#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Affiliate < ActiveRecord::Base
  belongs_to :account
  validates_presence_of :account_id
  
  belongs_to :party
  
  validates_presence_of :source_url
  validates_format_of :source_url, :with => /https?:\/\/.+\..+/i
  
  has_many :contact_requests
  
  def to_liquid
    AffiliateDrop.new(self)
  end
end
