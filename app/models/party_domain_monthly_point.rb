#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class PartyDomainMonthlyPoint < ActiveRecord::Base
  belongs_to :account
  belongs_to :domain
  belongs_to :party
  
  validates_presence_of :account_id, :domain_id, :party_id, :year, :month
  
  validates_uniqueness_of :party_id, :scope => [:account_id, :domain_id, :year, :month]
end
