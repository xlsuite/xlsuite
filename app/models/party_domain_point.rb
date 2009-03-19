#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class PartyDomainPoint < ActiveRecord::Base
  belongs_to :party
  belongs_to :domain
  belongs_to :account
  
  validates_presence_of :party_id, :account_id, :domain_id
  validates_uniqueness_of :party_id, :scope => [:account_id, :domain_id]
end
