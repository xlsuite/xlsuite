#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ForumTopic < ActiveRecord::Base
  belongs_to :account
  validates_presence_of :account_id
  before_validation { |r| r.account = r.forum.account if r.forum }

  acts_as_fulltext %w(title)

  belongs_to :forum, :counter_cache => 'topics_count'
  belongs_to :forum_category
  belongs_to :user, :class_name => 'Party', :foreign_key => 'user_id'
  after_save do |topic|
    ForumPost.update_all("forum_posts.forum_category_id = #{topic.forum_category_id}, forum_posts.forum_id = #{topic.forum_id}",
        "forum_posts.topic_id = #{topic.id}")
  end

  has_many :posts, :class_name => 'ForumPost', :foreign_key => 'topic_id', :order => 'forum_posts.created_at', :dependent => :destroy do
    def last
      @last_post ||= find(:first, :order => 'forum_posts.created_at desc')
    end
  end

  belongs_to :replied_by_user, :foreign_key => "replied_by", :class_name => "Party"

  validates_presence_of :forum_category_id, :forum_id, :user_id, :title

  before_create { |r| r.replied_at = Time.now.utc }
  attr_accessible :title
  # to help with the create form
  attr_accessor :body

  def after_initialize
    self.locked = false unless self.locked?
  end

  def to_liquid
    TopicDrop.new(self)
  end

  def voices
    posts.map { |p| p.user_id }.uniq.size
  end

  def hit!
    self.class.increment_counter :hits, id
  end

  def sticky?() sticky == 1 end

  def views() hits end

  def paged?() posts_count > 25 end

  def last_page
    (posts_count.to_f / 25.0).ceil.to_i
  end

  def editable_by?(user)
    return true if self.new_record?
    user && (user.id == user_id || user.can?(:admin_forum))
  end
  
  def main_identifier
    self.title
  end

  protected
  def party_display_name
    self.user ? self.user.display_name : nil
  end
end
