#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ForumCategory < ActiveRecord::Base
  include XlSuite::AccessRestrictions
  
  belongs_to :account
  validates_presence_of :account_id

  validates_presence_of :name

  has_many :forums, :dependent => :destroy do
    def readable_by(user)
      find(:all, :order => "position").select do |f|
        f.readable_by?(user)
      end
    end

    def writeable_by(user)
      find(:all, :order => "position").select do |f|
        f.writeable_by?(user)
      end
    end
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
    ForumCategoryDrop.new(self)
  end
end
