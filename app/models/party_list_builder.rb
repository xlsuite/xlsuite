#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class PartyListBuilder < RecipientListBuilder
  delegate :party, :to => :recipient

  def recipients
    [self.party]
  end

  # Override, because we want to use the E-Mail address specified here, and none other.
  def to_email_addresses
    # Attempt to get a name if we don't have one already.
    self.recipient.name = self.party.name.to_s if self.party && self.recipient && self.recipient.name.blank?
    [EmailContactRoute.new(:fullname => self.recipient.name.to_s, :address => self.recipient.address, :routable => self.party)]
  end

  def to_s
    self.to_email_addresses.first.to_formatted_s
  end
end
