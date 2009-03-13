#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

require "redcloth"

class ForumPost < ActiveRecord::Base
  belongs_to :account
  validates_presence_of :account_id
  before_validation { |r| r.account = (r.forum || r.topic).account if r.forum || r.topic }

  acts_as_fulltext %w(topic_title body)

  belongs_to :forum, :counter_cache => 'posts_count'
  belongs_to :forum_category
  belongs_to :user,  :class_name => 'Party', :foreign_key => 'user_id', :counter_cache => 'posts_count'
  belongs_to :topic, :class_name => 'ForumTopic',  :foreign_key => 'topic_id', :counter_cache => 'posts_count'
  
  before_create { |r| r.forum_id = r.topic.forum_id }
  before_save   { |r| r.body.strip! }
  before_save   :append_signature
  before_save   :render_body
  after_create  { |r| ForumTopic.update_all(['replied_at = ?, replied_by = ?, last_post_id = ?', r.created_at, r.user_id, r.id], ['id = ?', r.topic_id]) }
  after_destroy { |r| t = ForumTopic.find(r.topic_id) ; ForumTopic.update_all(['replied_at = ?, replied_by = ?, last_post_id = ?', t.posts.last.created_at, t.posts.last.user_id, t.posts.last.id], ['id = ?', t.id]) if t.posts.last }

  validates_presence_of :user_id, :body, :forum_category_id, :forum_id, :topic_id
  attr_accessible :body
  
  def to_liquid
    PostDrop.new(self)
  end

  def editable_by?(user)
    user && (user.id == user_id) || user.can?('admin_forum')
  end
  
  def append_signature
    return if !user.signature
    body = self.body
    body << '\n'
    body << user.signature
    self.body = body
  end
    
  def main_identifier
    self.body
  end
  
  protected
  def party_display_name
    self.user ? self.user.display_name : nil
  end    

  def render_body
    self.rendered_body = parse_redcloth_text(RedCloth.new(self.body).to_html)
    rescue
      self.rendered_body = self.body
  end

  def topic_title
    self.topic.title
  end

  private
  def parse_redcloth_text(text)
    text.gsub!(/\n+/, "\n")
    text.gsub!(/<\/\w+>.*(\n+).*<\w+>/) do |string|
      string.gsub!($1, "")
    end
    text.gsub!(/\n+([^(<.*>)]+)\n+/i) do |string|
      string = "<p>" << $1 << "</p>"
      string
    end
    text.gsub!(/<(\w+)>.*\n+.*<\/\1>/i) do |string|
      string.gsub!("\n", "<br />")
      string
    end
    text
  end
end
