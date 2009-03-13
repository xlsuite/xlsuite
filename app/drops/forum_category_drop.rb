#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ForumCategoryDrop < Liquid::Drop
  attr_reader :forum_category
  delegate :name, :description, :forums, :topics, :posts, :dom_id, :to => :forum_category

  def initialize(forum_category)
    @forum_category = forum_category
  end

  def url
    "/admin/forum_categories/#{forum_category.id}"
  end
end
