#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class EntryDrop < Liquid::Drop
  attr_reader :entry
  delegate :feed, :title, :link, :published_at, :summary, :content, :to => :entry

  def initialize(entry)
    @entry = entry
  end
end
