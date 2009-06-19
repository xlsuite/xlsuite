#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class BlogPostDrop < Liquid::Drop
  attr_reader :blog_post
  delegate :id, :dom_id, :excerpt, :title, :author_name, :link, :published_at, :created_at, :updated_at, 
  :permalink, :tags, :tag_list, :approved_comments_count, :unapproved_comments_count, :author, :author_profile,
  :deactivate_commenting_on, :to => :blog_post

  def initialize(blog_post)
    @blog_post = blog_post
  end

  def year
    published_at.year
  end

  def month
    published_at.month
  end

  def day
    published_at.day
  end

  def blog
    self.blog_post.blog.to_liquid
  end

  def body
    template = Liquid::Template.parse(blog_post.body)
    template.render(context)
  end

  def approved_comments
    self.blog_post.approved_comments unless self.blog_post.hide_comments
  end

  def comments_hidden?
    self.blog_post.hide_comments
  end

  def summary
    self.blog_post.parsed_excerpt
  end
  alias_method :content, :summary

  def average_rating
    (self.blog_post.average_comments_rating * 10).round.to_f / 10
  end

  def comments_always_approved
    self.blog_post.comment_approval_method =~ /always approved/i ? true : false
  end

  def comments_moderated
    self.blog_post.comment_approval_method =~ /^moderated$/i ? true : false
  end

  def comments_off
    self.blog_post.comment_approval_method =~ /no comments/i ? true : false
  end

  def raw_body
    self.blog_post.body
  end
  
  def json_body
    self.blog_post.body.to_json
  end
end
