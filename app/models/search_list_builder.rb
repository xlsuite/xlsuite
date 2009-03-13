#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class SearchListBuilder < RecipientListBuilder
  def recipients
    self.search.perform.last.map(&:last).select {|result| result.kind_of?(Party)}
  end

  def search
    self.account.searches.find(self.recipient_builder_id)
  end

  def to_s
    "search=#{self.search.name}"
  end
end
