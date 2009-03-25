#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Feed < ActiveRecord::Base
  belongs_to :account
  validates_presence_of :account_id
  
  belongs_to :created_by, :class_name => "Party", :foreign_key => :created_by_id
  belongs_to :updated_by, :class_name => "Party", :foreign_key => :updated_by_id
  validates_presence_of :created_by_id
  
  has_and_belongs_to_many :parties
  has_many :entries, :dependent => :delete_all

  acts_as_taggable
  acts_as_fulltext %w(label description url)
  validates_presence_of :url
  validates_uniqueness_of :label, :scope => [:account_id], :if => Proc.new{|feed| !feed.label.blank?}

  serialize :categories

  attr_accessor :refresh_now
  before_save :set_refreshed_at
  after_create :refresh_feed
  after_save :refresh_feed_if_flagged

  def to_liquid
    FeedDrop.new(self)
  end

  # Refreshes the feed's content and make sure the feed's URL is pointing
  # to the real URL (in case of auto-discovery).
  def refresh
    return if self.new_record?
    self.class.transaction do
      # TODO: Switch to this when we have Rails 2.0
      # self.entries.delete_all
      Entry.delete_all(["feed_id = ?", self.id])

      feed = self.open_feed(true)
      update_feed_attributes_from feed
      feed.entries.each do |entry|
        self.entries.create!(
          :content => entry.content, 
          :summary => entry.summary,
          :published_at => entry.time,
          :link => entry.link,
          :title => entry.title,
          :account_id => self.account_id 
        )
      end
     
      self.update_attributes!(
        :last_errored_at => nil,
        :error_class => nil,
        :error_message => nil,
        :backtrace => nil,
        :error_count => 0,
        :refreshed_at => Time.now.utc)
    end

  rescue Errno::EHOSTUNREACH, Errno::ENETUNREACH
    # Bad host?
    self.handle_error($!, 2.hours)

  rescue Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::ECONNABORTED
    # Couldn't connect: let's try again later
    self.handle_error($!, 1.day)

  rescue REXML::ParseException
    # Couldn't parse the feed: let's put off updating it until a bit later
    self.handle_error($!, 6.hours)
    
  rescue FeedTools::FeedAccessError
    # Couldn't retreive feed
    self.handle_error($!, 6.hours)
  
  rescue
    # All other errors
    self.handle_error($!, 6.hours)
  end

  def handle_error(exception, delta_try_again=2.days)
    ActiveRecord::Base.transaction do
      self.update_attributes(
        :last_errored_at => Time.now.utc,
        :backtrace => (exception.backtrace || []).join("\n"),
        :error_message => exception.message,
        :error_class => exception.class.name,
        :error_count => self.error_count + 1,
        :refreshed_at => delta_try_again.from_now.utc)

      if self.error_count % 3 == 0 then
        self.update_attribute(:refreshed_at, 30.days.from_now.utc)
        self.send_error_email
      end
    end
  end
  
  def send_error_email
    tos = [self.created_by, self.updated_by].compact
    return if tos.empty?
    tos = tos.map(&:main_email).map(&:email_address).reject(&:blank?).join(",")
    return if tos.blank?
    AdminMailer.deliver_feed_error_email(self, tos)
  end

  def attributes_for_copy_to(account)
    account_owner_id = account.owner ? account.owner.id : nil
    self.attributes.dup.merge(:account_id => account.id, :tag_list => self.tag_list, 
      :created_by_id => account_owner_id, :updated_by_id => account_owner_id)
  end

  protected
  def open_feed(force=false)
    cache = force ? nil : FeedTools.configurations[:feed_cache]
    returning(FeedTools::Feed.open(self.url, :feed_cache => cache)) do |feed|
      self.url = feed.href unless feed.href.blank? || self.frozen?
    end
  end

  def update_feed_attributes_from(feed)
    self.update_attributes(
      :title => feed.title,
      :subtitle => feed.subtitle,
      :tagline => feed.tagline,
      :publisher => feed.publisher.name,
      :language => feed.language,
      :guid => feed.guid,
      :copyright => feed.copyright,
      :abstract => feed.abstract,
      :author => feed.author.name,
      :categories => feed.categories,
      :published_at => feed.published 
    )
  end
  
  def set_refreshed_at
    self.refreshed_at = 10.years.ago unless self.refreshed_at
  end
  
  def refresh_feed_if_flagged
    self.refresh_feed if self.refresh_now
  end
  
  def refresh_feed
    MethodCallbackFuture.create!(:account => self.account, :model => self, :method => "refresh")
  end
end
