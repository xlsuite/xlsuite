class PartyDomainPoint < ActiveRecord::Base
  belongs_to :party
  belongs_to :domain
  belongs_to :account
  
  validates_presence_of :party_id, :account_id, :domain_id
  validates_uniqueness_of :party_id, :scope => [:account_id, :domain_id]
end
