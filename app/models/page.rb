#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

require "digest/md5"

class Page < Item
  include CacheControl

  acts_as_taggable
  acts_as_fulltext %w(title fullslug body status layout domain_patterns behavior)

  VALID_STATUSES = %w(draft reviewed protected published).freeze
  STATUSES_FOR_SELECT = VALID_STATUSES.map {|status| [status.titleize, status]}.freeze

  validates_presence_of :status, :domain_patterns
  validates_presence_of :layout, :if => :layout_required?
  validates_inclusion_of :status, :in => VALID_STATUSES
  before_validation {|p| p.fullslug = p.fullslug[1..-1] if p.fullslug && p.fullslug[0] == ?/}
  validates_format_of :fullslug, :with => %r{\A(?:\Z|[-:.\w%()][-:.\w%()/]*\Z)},
      :message => "must NOT begin with a slash (/) and can contain only letters, numbers, colons (:), dashes (-), underscores (_), dots (.) or percent signs (%)"

  before_save :set_default_fullslug
  before_validation :record_old_fullslug
  after_save :update_children_fullslug

  # We must rebuild the routes of each domain that we can be matched upon on every save.
  # This is not very efficient, but it's the best I can do at the moment.
  before_save :retrieve_old_object
  after_save :update_domain_routing_if_needed
  after_destroy :update_domain_routing_if_needed

  validate :title_template_syntax
  before_save :cache_title_template
  
  after_save :refresh_cached_pages_with_fullslug

  serialize :requirements

  def http_headers(domain, render_options=nil)
    layout = self.find_layout(domain)
    headers = Hash.new
    headers["Etag"] = Digest::MD5.hexdigest(render_options[:text] || render_options[:template]).inspect unless self.redirect?
    headers.merge(
      CacheControl.cache_control_headers(
          :updated_at => self.updated_at,
          :cache_timeout_in_seconds => self.cache_timeout_in_seconds || layout.cache_timeout_in_seconds,
          :cache_control_directive => self.cache_control_directive || layout.cache_control_directive || (readers.empty? && writers.empty? ? "public" : "private")))
  end

  def layout_required?
    true
  end

  def published?
    self.status == "published"
  end

  # Normalize the status to the downcased version.
  def status=(value)
    write_attribute(:status, (value || "").downcase)
  end

  def to_url
    "/#{self.fullslug}"
  end

  def fullslug=(value)
    write_attribute(:fullslug, value.gsub(%r{/+}, "/").gsub(%r{/$}, ""))
  end

  # Makes available a +page+ object to the Liquid::Template which responds_to:
  # * title: The page's title.
  # * body: The rendered body.
  # * url: The canonical URL of this page.
  # * updated_at: The page's last updated at time.
  # * guid: The page's UUID.
  # * author: The author's name.
  #
  # Also adds +current_user+, which responds to: name, title, position, email.
  #
  # This method expects the page to render, as well as the Party who made the
  # request, if any/known.
  def render_on_domain(domain, options={})
    user = options.delete(:current_user)
    account = options.delete(:current_account)
    account_owner = options.delete(:current_account_owner)

    options.nested_stringify_keys!
    assigns = options.merge("page" => PageDrop.new(self), "user" => PartyDrop.new(user), 
            "domain" => DomainDrop.new(domain), "user_affiliate_username" => options["user_affiliate_username"],
            "user_affiliate_id" => options["user_affiliate_username"],
            "account" => AccountDrop.new(account), "account_owner" => PartyDrop.new(account_owner),
            "logged_in" => options["logged_in"], "page_url" => options["current_page_url"], "page_slug" => options["current_page_slug"],
            "cart" => options["cart"].to_liquid, "current_time" => Time.now)
    registers = {"user" => user, "account" => account, "domain" => domain, "page_url" => options["current_page_url"]}

    logger.debug {"==> Assigns: #{assigns.keys.inspect}"}
    logger.debug {"==> Assigns: #{assigns['params'].inspect}"}
    context = Liquid::Context.new(assigns, registers, false)

    options.reverse_merge!("layout" => true)

    if options["layout"]
      the_layout = self.find_layout(domain)
      the_layout.render(context)
    else
      text = Liquid::Template.parse(self.body).render!(context)
      {:text => text, :content_type => "text/html; charset=UTF-8"}
    end
  end

  def parse_title_template
    Liquid::Template.parse(self.title)
  end

  def title_template
    @parsed_title_template ||= if self.cached_parsed_title.blank? then
                                 self.parse_title_template
                               else
                                 begin
                                   Marshal.load(self.cached_parsed_title)
                                 rescue
                                   logger.warn "Could not deserialize #{self.inspect}: #{$!}"
                                   parse_title_template
                                 end
                               end
  end

  def render_title(context=nil)
    self.title_template.render!(context)
  end

  def parent(domain)
    return nil if self.fullslug.blank?
    candidates = self.class.find(:all, :conditions => ["fullslug = ?", self.fullslug.split("/")[0..-2].join("/")])
    candidates.best_match_for_domain(domain)
  end

  def find_layout(domain)
    the_layout = self.account.layouts.find_by_domain_and_title(domain, self.layout)
    return the_layout if the_layout
    Layout.new(:title => "Default Rescue", :body => "{{ page.body }}", :content_type => "text/html", :encoding => "UTF-8")
  end

  def matches_domain?(domain)
    return true if domain.blank?
    self.domain_patterns.gsub(',', " ").split.any? do |pattern|
      domain.matches?(pattern)
    end
  end

  def depth
    self.fullslug.blank? ? 0 : 1 + self.fullslug.gsub(%r{[^/]}, "").size
  end

  def copy
    self.class.new(:fullslug => self.fullslug, :domain_patterns => self.domain_patterns, :layout => self.layout)
  end
  
  def full_copy
    self.class.new(self.attributes)
  end
  
  def convert_to_snippet
    snippet = Snippet.new(:account => self.account)
    snippet.title = "/" + self.fullslug
    snippet.body = self.body
    snippet.domain_patterns = self.domain_patterns
    snippet.published_at = Time.now.utc
    snippet.save
  end

  class << self
    # Returns the list of valid states.
    def valid_statuses
      VALID_STATUSES
    end

    # Returns the list of statuses, but correctly setup for use in a #select_tag.
    def statuses_for_select
      STATUSES_FOR_SELECT
    end

    def find_by_domain_and_fullslug(domain, fullslug)
      # Replace first slash
      pages = find_all_by_fullslug(fullslug.gsub(/^\//, ""))
      pages.blank? ? nil : pages.best_match_for_domain(domain)
    end

    # Returns the pages that have the specified slug, or returns an empty Array.
    def find_published_by_domain_and_fullslug(domain, fullslug)
      with_scope(:find => {:conditions => {:status => "published"}}) do
        find_by_domain_and_fullslug(domain, fullslug)
      end
    end

    # Returns the pages that have the specified slug, or raises
    # ActiveRecord::RecordNotFound.
    def find_published_by_domain_and_fullslug!(domain, fullslug)
      returning find_published_by_domain_and_fullslug(domain, fullslug) do |page|
        raise ActiveRecord::RecordNotFound unless page
      end
    end

    def find_all_in_domain(domain)
      get_all_by_fullslug.group_by(&:fullslug).values.map do |pages|
        pages.best_match_for_domain(domain)
      end.compact.sort_by(&:fullslug)
    end

    def get_all_by_fullslug
      find(:all, :order => "fullslug")
    end

    # Returns all pages whose title matches %<tt>title</tt>%
    def find_all_with_partial_title(title)
      self.find(:all, :conditions => ["title LIKE ?", "%#{title}%"], :order => "fullslug")
    end

    # Expects a block
    def disable_domain_routing_update
      raise ArgumentError, "No block given" unless block_given?
      Thread.current["xlsuite:domain_routing_disabled"] = true
      begin
        yield
      ensure
        Thread.current["xlsuite:domain_routing_disabled"] = nil
      end
    end
  end
  
  def retrieve_old_object
    @_old_object = nil
    return if self.new_record?
    @_old_object = self.class.find(self.id)
  end

  def update_domain_routing_if_needed
    if @_old_object
      self.update_domain_routing if self.domain_patterns != @_old_object.domain_patterns || self.fullslug != @_old_object.fullslug
    else
      self.update_domain_routing
    end
  end
  
  def update_domain_routing
    return if Thread.current["xlsuite:domain_routing_disabled"]
    matched_domains = self.account.domains.select do |domain|
      self.matches_domain?(domain)
    end
    
    return if matched_domains.empty?
    futures = nil
    matched_domains.each_slice(10) do |mds|
      futures = MethodCallbackFuture.all(:conditions => ["account_id=? AND status=? AND args LIKE '%rebuild_route%'", self.account.id, "unstarted"])
      next if futures.map{|e| e.args[:ids].sort}.include?(mds.map(&:id).sort) 
      MethodCallbackFuture.create!(:system => true, :account_id => self.account.id, :models => mds, :method => :rebuild_routes!, :priority => 90)
    end
  end
  
  def self.to_new_from_item_version(item_version)
    attrs = item_version.attributes
    %w(id item_id versioned_type cached_parsed_title cached_parsed_body).each do |attr_name|
      attrs.delete(attr_name)
    end
    page = self.new(attrs)
    page
  end

  protected
  def record_old_fullslug
    @old_fullslug = self.fullslug
    return @old_fullslug if self.id.blank?
    @old_fullslug = Page.find(self.id).fullslug
    @old_fullslug
  end  

  def update_children_fullslug
    return true if @old_fullslug.blank? || @old_fullslug == self.fullslug
    self.account.pages.find(:all, :conditions => ["fullslug LIKE ?", "#{@old_fullslug}/%"]).each do |page|
      page.update_attribute(:fullslug, page.fullslug.sub(@old_fullslug, self.fullslug))
    end
    true
  end

  def set_default_fullslug
    self.fullslug = "" if self.fullslug.nil?
  end

  def title_template_syntax
    begin
      self.parse_title_template
    rescue SyntaxError
      self.errors.add_to_base "Title: #{$!}"
    end
  end

  def cache_title_template
    self.cached_parsed_title = Marshal.dump(self.parse_title_template)
  end
  
  def refresh_cached_pages_with_fullslug
    CachedPage.force_refresh_on_account_fullslug!(self.account, self.fullslug)
  end
end
