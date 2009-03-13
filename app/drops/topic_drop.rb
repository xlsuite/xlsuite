#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class TopicDrop < Liquid::Drop
  attr_reader :topic
  delegate :title, :posts, :forum, :forum_category, :dom_id, :to => :topic

  def initialize(topic)
    @topic = topic
  end

  def url
    "/admin/forum_categories/#{forum_category.id}/forums/#{forum.id}/topics/#{topic.id}"
  end
end
