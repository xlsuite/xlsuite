#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class BookRelation < ActiveRecord::Base
  belongs_to :book
  belongs_to :party
  validates_presence_of :classification
end
