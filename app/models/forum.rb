#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Forum < ActiveRecord::Base
  include XlSuite::AccessRestrictions
      
  belongs_to :account
  validates_presence_of :account_id

  acts_as_list :scope => :forum_category  
  before_create :set_position
  
  belongs_to :forum_category
  validates_presence_of :name, :forum_category_id
  after_save do |forum|
    ForumTopic.update_all("forum_topics.forum_category_id = #{forum.forum_category_id}",
        "forum_topics.forum_id = #{forum.id}")
    ForumPost.update_all("forum_posts.forum_category_id = #{forum.forum_category_id}",
        "forum_posts.forum_id = #{forum.id}")
  end

  has_many :topics, :class_name => 'ForumTopic', :order => 'sticky desc, replied_at desc', :dependent => :destroy do
    def first
      @first_topic ||= find(:first)
    end
  end

  has_many :posts, :class_name => 'ForumPost', :order => 'forum_posts.created_at desc' do
    def last
      @last_post ||= find(:first, :include => :user)
    end
  end
  
  def to_liquid
    ForumDrop.new(self)
  end

  protected
  
  def set_position
    forum = self.account.forums.find(:first, :conditions => ["forum_category_id = ? AND position = ?", self.forum_category.id, self.position])
    self.send("increment_positions_on_lower_items", self.position) if forum
  end
  
  private
  
  def add_to_list_bottom
  end  
end
