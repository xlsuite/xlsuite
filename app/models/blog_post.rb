#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

require "ostruct"

class BlogPost < ActiveRecord::Base
  include XlSuite::Commentable
  
  acts_as_taggable
  acts_as_fulltext %w(title), %w(excerpt body author_name blog_title blog_subtitle blog_label blog_author_name tags_as_text)
  acts_as_reportable :columns => %w(title excerpt body author_name link permalink)

  named_scope :published, lambda {{:conditions => ["published_at < ?", Time.now.utc] }}
  named_scope :by_publication_date, :order => "published_at DESC"

  belongs_to :account
  belongs_to :domain
  belongs_to :blog
  belongs_to :author, :class_name => "Party", :foreign_key => "author_id"
  belongs_to :editor, :class_name => "Party", :foreign_key => "editor_id"

  before_validation :set_default_permalink

  validates_presence_of :account_id, :domain_id, :blog_id, :title, :author_id
  validates_format_of :link, :with => %r{\A(?:ftp|https?)://.*\Z}i, :allow_nil => true, :message => "must be absolute url", :if => :link_not_blank
  validates_format_of :permalink, :with => /\A[-\w]+\Z/i, :message => "can contain only a-z, A-Z, 0-9, _ and -, cannot contain space(s)", :if => :title_not_blank

  before_save :set_author_name
  before_save :set_domain_if_blank
  before_save :set_parsed_excerpt
  
  def to_liquid
    BlogPostDrop.new(self)
  end

  def writeable_by?(party)
    return true if self.author.profile && self.author.profile.writeable_by?(party)
    return true if self.new_record?
    return false unless party
    return true if self.blog.writers.empty?
    self.blog.writers.any? do |group|
      party.member_of?(group)
    end
  end
  
  def self.count_by_month(cutoff_at=10.years.ago)
    self.find(:all, :select => "COUNT(*) as count_all, YEAR(published_at) AS year_published_at, MONTH(published_at) AS month_published_at",
        :order => "YEAR(published_at), MONTH(published_at)",
        :conditions => ["published_at >= ?", cutoff_at],
        :group => "YEAR(published_at), MONTH(published_at)").map do |row|
      OpenStruct.new(:published_at => Time.utc(row.year_published_at, row.month_published_at),
          :count => row.count_all)
    end
  end
  
  def comment_approval_method
    return "no comments" if self.deactivate_commenting_on && (self.deactivate_commenting_on <= Date.today)
    self.blog.comment_approval_method
  end

  def attributes_for_copy_to(account)
    account_owner_id = account.owner ?  account.owner.id : nil
    attributes = self.attributes.dup.symbolize_keys.merge(:account_id => account.id, 
                :author_id => account_owner_id, :editor_id => account_owner_id, 
                :tag_list => self.tag_list)
    attributes.delete(:blog_id)
    attributes
  end
  
  def author_profile
    self.author.profile
  end
  
  def send_comment_email_notification(comment)
    if self.blog.author && self.blog.author.confirmed? && self.blog.author.blog_post_comment_notification?
      AdminMailer.deliver_comment_notification(comment, "blog post \"#{self.title}\"", self.blog.author.main_email.email_address)
    end
  end

  protected

  def set_author_name
    self.author_name = self.author ? self.author.name.to_s : ""
  end

  def tags_as_text
    self.tags.map(&:name)
  end

  def blog_title
    self.blog.title
  end

  def blog_subtitle
    self.blog.subtitle
  end

  def blog_label
    self.blog.label
  end

  def blog_author_name
    self.blog.author_name
  end

  def link_not_blank
    !self.link.blank?
  end

  def title_not_blank
    !self.title.blank?
  end

  def set_default_permalink
    return unless self.permalink.blank?
    self.permalink = self.title.to_url
  end
  
  def set_domain_if_blank
    if self.domain.blank? && self.domain_id.blank?
      self.domain = self.blog.domain
      self.domain_id = self.blog.domain_id
    end
  end
  
  def set_parsed_excerpt
    text = self.excerpt.blank? ? self.body : self.excerpt
    
    assigns = {"domain" => DomainDrop.new(self.domain), "account" => AccountDrop.new(self.account), 
               "account_owner" => PartyDrop.new(self.account.owner)}
    registers = {"account" => self.account, "domain" => self.domain}

    context = Liquid::Context.new(assigns, registers, false)
    self.parsed_excerpt = Liquid::Template.parse(text).render(context)
    true
  end
end
