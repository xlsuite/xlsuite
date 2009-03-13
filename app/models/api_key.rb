#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ApiKey < ActiveRecord::Base
  belongs_to :account
  belongs_to :party
  validates_presence_of :account_id, :party_id
  before_validation {|k| k.account = k.party.account if k.party}

  before_create :generate_api_key
  acts_as_fulltext %w(key party_name)

  def party_name
    party.name.to_s
  end

  def to_s
    self.key
  end

  protected
  def generate_api_key
    uuid = UUID.random_create
    self.key = uuid.to_s
  end
end
