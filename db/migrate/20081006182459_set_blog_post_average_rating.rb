class SetBlogPostAverageRating < ActiveRecord::Migration
  def self.up
    BlogPost.find(:all).each do |post|
      post.update_attribute("average_rating", post.average_comments_rating)
    end
  end

  def self.down
    BlogPost.update_all "average_rating = 0.0"
  end

class ::BlogPost < ActiveRecord::Base
  has_many :comments, :as => :commentable, :order => "created_at DESC"
  
  def approved_comments
    self.comments.find(:all, :conditions => "approved_at IS NOT NULL")
  end

  def approved_comments_count
    self.comments.count(:conditions => "approved_at IS NOT NULL")
  end
  
  def average_comments_rating
    return 0 if self.approved_comments_count == 0
    ratings_sum = 0
    ratings = self.approved_comments.map(&:rating).reject(&:blank?)
    ratings.each{|r| ratings_sum += r} unless ratings.blank?
    ratings_sum/self.approved_comments_count.to_f
  end
end

class Comment < ActiveRecord::Base
  belongs_to :commentable, :polymorphic => true 
end
end

