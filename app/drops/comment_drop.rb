#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class CommentDrop < Liquid::Drop
  attr_reader :comment
  delegate :id, :rating, :body, :name, :url, :email, :user_agent, :referrer_url, :commentable_type, :commentable,
      :approved_at, :created_at, :updated_at, :author, :author_profile, :to => :comment

  def initialize(comment)
    @comment = comment
  end
  
  def posted_by
    if self.comment.url.blank?
      return "#{self.comment.name}"
    else
      return "<a href='#{self.comment.url}'>#{self.comment.name}</a>"
    end
    
  end
end
