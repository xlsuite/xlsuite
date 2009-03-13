#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class FeedDrop < Liquid::Drop
  attr_reader :feed
  delegate :label, :title, :subtitle, :tagline, :publisher, :language, :guid, :copyright,
    :abstract, :author, :categories, :published_at, :url, :description, :refreshed_at,
    :entries, :to => :feed

  def initialize(feed)
    @feed = feed
  end
end
