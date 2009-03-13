#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class PostDrop < Liquid::Drop
  attr_reader :post
  delegate :body, :render_body, :topic, :forum, :forum_category, :created_at, :dom_id, :to => :post

  def initialize(post)
    @post = post
  end

  def url
    "/admin/forum_categories/#{forum_category.id}/forums/#{forum.id}/topics/#{topic.id}#forum_post_#{post.id}"
  end
end
