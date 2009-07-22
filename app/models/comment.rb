#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Comment < ActiveRecord::Base
  include XlSuite::Flaggable
  
  COMMENTABLES = %w(BlogPost Listing Product Profiles)
  
  attr_protected :approved_at, :referrer_url, :user_agent
  
  acts_as_reportable :columns => %w(name url email referrer_url body rating commentable_type spam spaminess)
  
  belongs_to :account
  belongs_to :domain
  belongs_to :commentable, :polymorphic => true
  
  validates_inclusion_of :rating, :in => 1..5, :allow_nil => true
  
  validates_presence_of :account_id, :commentable_id, :commentable_type, :name
  validates_format_of :email, :with => EmailContactRoute::ValidAddressRegexp, :allow_nil => true

  validates_format_of :referrer_url, :with => %r{\A(?:ftp|https?)://.*\Z}, :message => "must be absolute url", :if => :referrer_url_not_blank
  
  belongs_to :created_by, :class_name => "Party", :foreign_key => :created_by_id
  belongs_to :updated_by, :class_name => "Party", :foreign_key => :updated_by_id
  
  before_validation :ensure_absolute_url, :if => :url_not_blank
  before_validation :set_rating
  before_create :set_approved
  after_save :send_comment_email_notification
  
  after_save :set_commentable_average_rating
  after_destroy :set_commentable_average_rating
  
  def to_liquid
    CommentDrop.new(self)
  end
  
  def contains_blacklist_words
    return false unless self.domain
    blacklist_words = self.domain.get_config("blacklist_words")
    blacklist_words_array = blacklist_words.split(',').map(&:strip).reject(&:blank?)
    return false if blacklist_words_array.join("").blank?
    blacklist_regex = Regexp.new("(#{blacklist_words_array.join('|')})", true)
    %w(name url email body).each do |column|
      return true if self.send(column) =~ blacklist_regex
    end
    false
  end
  
  def do_spam_check!
    response = defensio.ham?(
      self.request_ip, self.created_at, self.name, "comment", {:body => self.body, :email => self.email, :referrer => self.referrer_url, 
      :authenticated => !self.created_by_id.blank?, :author_url => self.url}
    )
    if response[:status] == "fail"
      raise response[:message]
    else
      (response[:spam] || self.contains_blacklist_words) ? mark_as_spam!(response[:spaminess], response[:signature]) : mark_as_ham!(response[:spaminess], response[:signature])
      self.save!
    end
  end

  def mark_as_ham!(spaminess, signature)
    self.spam = false
    self.spaminess = spaminess
    self.defensio_signature = signature
  end

  def mark_as_spam!(spaminess, signature)
    self.spam = true
    self.spaminess = spaminess
    self.defensio_signature = signature
  end

  def confirm_as_ham!
    # call save to trigger after_save callbacks
    self.spam = false
    self.save!
    defensio.mark_as_ham(self)
  end

  def confirm_as_spam!
    # call save to trigger after_save callbacks
    self.spam = true
    self.save!
    defensio.mark_as_spam(self)
  end
  
  def author
    self.created_by
  end
  
  def author_profile
    self.created_by ? self.created_by.profile : nil
  end
  
  def point_worth
    return 0 if self.body.blank? || self.rating.nil? || !self.approved? || self.body.size < 20
    case self.commentable_type
    when /listing/i
      50
    when /blogpost/i
      10
    when /product/i
      25
    when /profile/i
      50
    else
      0
    end
  end
  
  def add_points!
    return if self.point_added?
    ActiveRecord::Base.transaction do
      points = self.point_worth
      return if points == 0
      timestamp = self.created_at - 86400
      count = self.account.comments.count(:conditions => ["created_at >= ? AND created_at <= ? AND point_added = ?", timestamp, self.created_at, true])
      if count < 20
        self.created_by.add_point_in_domain(points, self.domain)
        self.set_point_added(true)
      end
      if self.commentable_type =~ /blogpost/
        blog_post = comment.commentable
        # Add points for the blog post author since somebody wrote a comment on his/her post
        blog_post.author.add_point_in_domain(points, comment.domain) if blog_post.author.id != self.created_by_id
      end
    end
  end
  
  def remove_points!
    return unless self.point_added?
    points = self.point_worth
    return if points == 0    
    self.created_by.add_point_in_domain(-points, self.domain)
    self.set_point_added(false)
  end
  
  # Calling this method will not execute callbacks
  def set_point_added(new_value)
    value = new_value ? "1" : "0"
    Comment.update_all("point_added = #{value}", "id = #{self.id}")
  end
  
  def approved?
    !self.approved_at.blank?
  end
  
  protected
  def defensio
    @defensio ||= Mephisto::SpamDetectionEngines::DefensioEngine::new
  end
  
  def set_rating
    self.rating = self.rating.blank? ? nil : self.rating.to_i
  end
  
  def url_not_blank
    !self.url.blank?
  end
  
  def referrer_url_not_blank
    !self.referrer_url.blank?
  end
  
  def set_approved
    if (self.commentable.respond_to?(:author_id) && (self.created_by_id == self.commentable.author_id)) || (self.created_by_id == self.account.owner.id)
      self.approved_at = Time.now
      return true
    end
    if self.commentable.respond_to?(:comment_approval_method)
      case self.commentable.comment_approval_method
        when /always approved/i
          self.approved_at = Time.now
        when /no comments/i
          self.errors.add_to_base("Sorry, comments are disabled for this #{self.commentable_type.titleize}")
          return false
      end
    end
  end
  
  def set_commentable_average_rating
    if self.commentable.respond_to?(:average_rating=) && self.commentable.respond_to?(:average_comments_rating)
      self.commentable.update_attribute("average_rating", self.commentable.reload.average_comments_rating)
    end
  end
  
  def after_flagging_approved_callback
    return unless self.approved?
    flagging_limit = self.domain.get_config("unapprove_comment_after_x_flaggings")
    return if flagging_limit == 0
    if flagging_limit <= self.reload.approved_flaggings_count
      self.update_attribute("approved_at", nil)
    end
  end
  
  def ensure_absolute_url
    unless self.url =~ /\A(?:ftp|https?):\/\/.*\Z/
      self.url = if self.url =~ /.*s:\/\//
        self.url.gsub(/.*s:\/\//, "https://")
      elsif self.url =~ /.*:\/\//
        self.url.gsub(/.*:\/\//, "http://")
      else
        "http://" + self.url
      end
    end
  end
  
  def send_comment_email_notification
    if ( !self.spam && self.approved_at && ( self.spam_changed? || self.approved_at_changed? ) )
      unless self.sent_email_notification
        self.commentable.send_comment_email_notification(self) if self.commentable
        self.update_attribute("sent_email_notification", true)
      end
    end
    true
  end
end
