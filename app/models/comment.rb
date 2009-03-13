#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Comment < ActiveRecord::Base
  attr_protected :approved_at, :referrer_url, :user_agent
  
  acts_as_reportable :columns => %w(name url email referrer_url body rating commentable_type spam spaminess)
  
  belongs_to :account
  belongs_to :domain
  belongs_to :commentable, :polymorphic => true
  
  validates_inclusion_of :rating, :in => 1..5, :allow_nil => true
  
  validates_presence_of :account_id, :commentable_id, :commentable_type, :name
  validates_format_of :email, :with => EmailContactRoute::ValidAddressRegexp, :allow_nil => true
  validates_format_of :url, :with => %r{\A(?:ftp|https?)://.*\Z}, :message => "must be absolute url", :if => :url_not_blank
  validates_format_of :referrer_url, :with => %r{\A(?:ftp|https?)://.*\Z}, :message => "must be absolute url", :if => :referrer_url_not_blank
  
  belongs_to :created_by, :class_name => "Party", :foreign_key => :created_by_id
  belongs_to :updated_by, :class_name => "Party", :foreign_key => :updated_by_id
  
  before_validation :set_rating
  before_create :set_approved
  
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
    self.update_attribute("spam", false)
    defensio.mark_as_ham(self)
  end

  def confirm_as_spam!
    self.update_attribute("spam", true)
    defensio.mark_as_spam(self)
  end
  
  def author
    self.created_by
  end
  
  def author_profile
    self.created_by.profile
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
    if self.commentable.respond_to?(:author_id) && (self.created_by_id == self.commentable.author_id)
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
end
