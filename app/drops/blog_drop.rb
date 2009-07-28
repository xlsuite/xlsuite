#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class BlogDrop < Liquid::Drop
  attr_reader :blog

  delegate :id, :dom_id, :title, :subtitle, :label, :author_name, :created_at, :updated_at, 
  :tags, :tag_list, :last_updated_at, :created_by_id, :created_by, :comment_approval_method, 
  :author, :author_profile, :private, :products, :to => :blog

  def initialize(blog)
    @blog = blog
  end

  def year
    created_at.year
  end

  def month
    created_at.month
  end

  def day
    created_at.day
  end

  def before_method(name)
    return self.count_by_month($1.to_i.months.ago) if name =~ /^count_previous_(\d)+_month(s)?$/
    nil
  end

  def posts
    self.blog.posts.published.by_publication_date.map(&:to_liquid)
  end
  
  def all_posts
    self.blog.posts.by_publication_date.map(&:to_liquid)
  end
  
  def posts_tags
    self.blog.posts.tags
  end

  def editable_by_user
    return false unless self.context && self.context["user"] && self.context["user"].party
    return true if self.context["user"].party.can?(:edit_blogs)
    return self.context["user"].party.id == self.blog.created_by_id
  end
  
  protected

  def count_by_month(cutoff_at)
    self.blog.count_by_month(cutoff_at).map { |e| OpenStructDrop.new(e)}
  end
end
