#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

# We must require redirect, or else the calls to Account#pages will not register the fact that there are subclasses of Page.
require "redirect"

class Domain < ActiveRecord::Base
  belongs_to :account
  validates_presence_of :account_id
  
  belongs_to :domain_subscription
  has_many :party_points, :class_name => "PartyDomainPoint"

  validates_presence_of :name, :if => :regular_domain?
  validates_uniqueness_of :name, :if => :regular_domain?
  validates_format_of :name, :with => /\A(?:[a-z0-9][-\w.]+\.[a-z]{2,6}|127.0.0.1| )\Z/, :if => :regular_domain?
  validates_length_of :name, :in => 4..63, :if => :regular_domain?
  validate :name_prefix_match
  
  before_validation :set_domain_level

  serialize :routes

  acts_as_money :price
  
  attr_protected :activated_at

  after_destroy :cancel_domain_subscription

  # Domains can now have 1 of 4 roles.
  # Template are domains that mostly reference CSS and Layouts.
  TemplateRole = "template".freeze
  
  # HouseTemplate are Templates used by the "Create website for listings" action
  HouseTemplateRole = "house_template".freeze

  # Modules are domains which hold a set of pages for implementing a function:
  # Cart, Product Catalog, Listings, etc.
  ModuleRole = "module".freeze

  # Browsing are modules which customers would create for themselves.  This is the default value.
  BrowsingRole = "browsing".freeze

  AvailableRoles = [BrowsingRole, ModuleRole, TemplateRole, HouseTemplateRole].freeze
  validates_inclusion_of :role, :in => AvailableRoles

  named_scope :in_bucket, lambda {|number|
      { :joins      => "INNER JOIN domain_subscriptions ON domain_subscriptions.id = domains.domain_subscription_id",
        :conditions => ["domain_subscriptions.bucket = ? AND domain_subscriptions.cancelled_at IS NULL AND domains.activated_at IS NOT NULL", number]}}

  def activate!(now=Time.now.utc)
    self.update_attribute(:activated_at, now)
  end

  def pages
    self.account.pages.select do |page|
      page.matches_domain?(self)
    end
  end

  def rebuild_routes
    self.routes = returning(Hash.new) do |routes|
      logger.debug {"==> Rebuilding #{self.pages.size} pages in domain #{name}"}
      self.pages.group_by(&:fullslug).each do |fullslug, pages|
        logger.debug {"==> #{fullslug.inspect} matches #{pages.size} pages"}
        requirements = pages.detect(&:requirements) || {}
        routes.merge!(
          XlSuite::Routing.build(fullslug => {:pages => pages.map(&:id), :requirements => requirements}
        ))
      end
    end
  end

  def rebuild_routes!
    rebuild_routes
    save!
  end

  def recognize(uri)
    values = XlSuite::Routing.recognize(uri, self.routes || self.rebuild_routes)
    return nil if values.blank? || values[:pages].blank?
    pages = self.account.pages.find(values[:pages]).best_match_for_domain(self)
    [pages, values[:params]]
  end

  def recognize!(uri)
    returning(recognize(uri)) do |result|
      raise ActiveRecord::RecordNotFound if result.nil?
    end
  end

  def nice_name
    self.name.sub(/[.]template.*$/i, "").titleize
  end

  def to_s
    self.name
  end
  
  def to_mail_domain
    self.to_s.gsub(/^www\./,"")
  end

  def matches?(pattern)
    return true if pattern.blank? || pattern == "*"
    self.name =~ Regexp.new("\\A" + pattern.gsub(".", "[.]").gsub("**", ".+").gsub("*", "[^.]+") + "\\Z")
  end
  
  def get_config(name)
    Configuration.get(name, self)
  end

  def find_thumbnails
    self.account.assets.get_tagged_with([self.name, "thumbnail"], :order => "created_at DESC")
  end
  
  def to_liquid
    DomainDrop.new(self)
  end
  
  def bypass!
    ActiveRecord::Base.transaction do
      self.domain_subscription.destroy if self.domain_subscription.domains.count <= 1
      self.domain_subscription = self.account.create_free_domain_subscription
      self.activated_at = Time.now
      self.save!
    end
  end
  
  def parent
    return nil if self.new_record?
    domain_name = self.name.split(".")
    domain_name.shift
    if domain_name.size > 1
      return Domain.find_by_name(domain_name.join("."))
    end
    if domain_name.last == "localhost"
      return Domain.find_by_name(domain_name.join("."))
    end
    nil
  end

  protected
  def set_domain_level
    self.level = self.name.split(".").size - 1
  end
    
  def name_prefix_match
    return if name.blank?

    invalid_prefixes = %w(mail gopher ftp news admin pop imap smtp svn git darcs hg mercurial)
    invalid_prefixes << "test" if RAILS_ENV != "test"
    invalid_prefixes.each do |prefix|
      if name.starts_with?(prefix+".")
        self.errors.add(:name, "cannot start with: #{prefix.inspect}")
      end
    end
  end

  def regular_domain?
    !["127.0.0.1", "localhost", " "].include?(self.name) && self.name !~ /\.localhost$/i
  end
  
  def cancel_domain_subscription
    return if self.activated_at.blank?
    raise "A domain need to have a domain subscription assigned to it" unless self.domain_subscription
    #TODO: the following needs to save domain name before destroying it later on
    if self.domain_subscription.domains.count == 0
      self.domain_subscription.update_attributes(:cancelled_at => Time.now)
    end
  end
end
