#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class GroupListBuilder < RecipientListBuilder
  def initialize(recipient)
    @recipient = recipient
  end

  def recipients
    return [] if self.recipient.inactive?
    self.group.parties
  end

  def group
    self.account.groups.find_by_id(@recipient.recipient_builder_id)
  end

  def to_s
    if self.group
      self.group.name
    else
      "[GROUP DELETED]"
    end
  end
end
