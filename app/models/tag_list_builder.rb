#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class TagListBuilder < RecipientListBuilder
  delegate :tag_syntax, :to => :recipient

  def tag_names
    return [] if self.tag_syntax.blank?
    self.tag_syntax.split(/\s+AND\s+/)
  end

  def recipients
    return [] if self.recipient.inactive?
    tags = self.tag_names
    self.parties.find_tagged_with(:all => tags)
  end

  def to_s
    "tag=#{self.tag_syntax}"
  end
end
