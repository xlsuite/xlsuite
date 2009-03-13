#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ForumDrop < Liquid::Drop
  attr_reader :forum
  delegate :name, :description, :forum_category, :topics, :posts, :dom_id, :to => :forum

  def initialize(forum)
    @forum = forum
  end

  def url
    "/admin/forum_categories/#{forum.forum_category.id}/forums/#{forum.id}"
  end
end
