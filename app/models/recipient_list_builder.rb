#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class RecipientListBuilder
  attr_reader :recipient
  delegate :account, :logger, :email, :recipient_builder_id, :to => :recipient
  
  def initialize(recipient)
    @recipient = recipient
  end

  def parties
    self.account.parties
  end

  def to_email_addresses
    party_ids = self.recipients.flatten.compact.map(&:id).uniq
    return [] if party_ids.blank?
    self.account.email_contact_routes.find(:all, :group => "routable_id", :conditions => "routable_type = 'Party' AND routable_id IN (#{party_ids.join(",")})").reject(&:blank?).uniq
  end
end
