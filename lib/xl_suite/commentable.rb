#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  module Commentable
    def self.included(base)
      base.send :extend, Commentable::ClassMethods
      
      base.send("attr_accessor", :current_domain)
      base.before_validation_on_create :set_comment_approval_method
      base.validates_format_of :comment_approval_method, :with => /(moderated)|(always\sapproved)|(no comments)/i
      
      base.has_many :comments, :as => :commentable, :order => "created_at DESC", :dependent => :destroy
    end
    
    module ClassMethods
      def recalculate_average_rating
        self.find(:all).each do |commentable|
          commentable.update_attribute("average_rating", commentable.average_comments_rating)
        end
        true
      end
    end 
    
    def approved_comments
      self.comments.find(:all, :conditions => "approved_at IS NOT NULL")
    end
  
    def unapproved_comments
      self.comments.find(:all, :conditions => "approved_at IS NULL")
    end
  
    def approved_comments_count
      self.comments.count(:conditions => "approved_at IS NOT NULL")
    end
  
    def unapproved_comments_count
      self.comments.count(:conditions => "approved_at IS NULL")
    end
    
    def unapproved_ham_comments
      self.comments.all(:conditions => "approved_at IS NULL AND spam = 0")
    end
    
    def unapproved_ham_comments_count
      self.comments.count(:conditions => "approved_at IS NULL AND spam = 0")
    end
    
    def spam_comments
      self.comments.all(:conditions => "spam = 1")
    end
    
    def spam_comments_count
      self.comments.count(:conditions => "spam = 1")
    end
    
    def average_comments_rating
      return 0 if self.approved_comments_count == 0
      ratings_sum = 0
      ratings = self.approved_comments.map(&:rating).reject(&:blank?)
      return 0 if ratings.blank?
      ratings.each{|r| ratings_sum += r}
      ratings_sum/ratings.size.to_f
    end
  
    def approve_all_comments
      count = 0
      self.comments.find(:all, :conditions => "approved_at IS NULL").each do |comment|
        comment.approved_at = Time.now
        count += 1 if comment.save
      end
      count
    end
    
    def set_comment_approval_method
      if self.comment_approval_method.blank?
        d = nil
        d = self.domain if self.respond_to?(:domain)
        d = self.current_domain if d.blank?
        self.comment_approval_method = d.blank? ? self.account.get_config(:default_comment_approval_method) : 
                                                                    d.get_config(:default_comment_approval_method) 
      end
      true
    end
    protected :set_comment_approval_method
    
    def send_comment_email_notification(comment)
      true
    end
  end
end
