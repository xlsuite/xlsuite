#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Layout < ActiveRecord::Base
  acts_as_versioned :limit => 20, :if_changed => [:title, :content_type, :body, :domain_patterns]
  self.non_versioned_columns << 'delta'
  
  belongs_to :account
  validates_presence_of :account_id

  include XlSuite::AccessRestrictions
  include DomainPatternsSplitter
  include CacheControl

  validates_presence_of :title, :content_type
  belongs_to :creator, :class_name => "Party", :foreign_key => :creator_id
  belongs_to :updator, :class_name => 'Party', :foreign_key => :updator_id

  acts_as_fulltext %w(title content_type body creator_as_text)

  validates_presence_of :domain_patterns
  before_validation :ensure_domain_patterns_not_empty

  before_validation :record_old_title
  after_save :update_existing_page_layouts

  validate :template_syntax
  before_save :cache_parsed_template

  before_create :guess_cache_control_directives

  attr_accessor :rename_pages, :skip_set_modified
  
  before_create :generate_random_uuid
  before_save :set_modified

  validates_length_of :body, :maximum => 60.kilobytes

  # Parse or reuse an already parsed template.
  def parsed_template
    @parsed_template ||= if self.cached_parsed_template.nil? then
                           self.parse_template
                         else
                           self.reload_cached_parsed_template
                         end
  end

  def available_on?(domain)
    !!self.patterns.detect {|pattern| domain.matches?(pattern)}
  end

  def render(liquid_context)
    text = self.parsed_template.render!(liquid_context)
    t_content_type = [self.content_type]
    t_content_type << "charset=#{self.encoding}" unless self.encoding.blank?
    {:text => text, :content_type => t_content_type.join("; ")}
  end

  def body=(value)
    @parsed_template = nil
    write_attribute(:body, value.blank? ? nil : value.strip.chomp)
  end

  class << self
    def find_all_by_title(title=nil)
      if title.blank? then
        find(:all, :order => "title")
      else
        find(:all, :conditions => ["title = ?", "#{title}"], :order => "title")
      end
    end

    def find_by_domain_and_title(domain, title)
      layouts = find_all_by_title(title)
      layouts.blank? ? nil : layouts.best_match_for_domain(domain)
    end

    def find_by_domain_and_title!(domain, title)
      returning find_by_domain_and_title(domain, title) do |layout|
        raise ActiveRecord::RecordNotFound, "Could not find a layout titled #{title.inspect} on domain #{domain.name.inspect}" unless layout
      end
    end

    def default(domain)
      page = Page.find_published_by_domain_and_fullslug(domain, "")
      if page && !page.layout.blank? then
        page.find_layout(domain)
      else
        self.new(:content_type => "text/html", :encoding => "UTF-8",
                 :title => "Untitled", :body => "{{ page.body }}")
      end
    end
  end

  def attributes_for_copy_to(account, options)
    domain_patterns = options[:domain_patterns] || "**"

    t_updator_id = self.updator_id
    if t_updator_id
      updator = account.parties.find_by_id(t_updator_id)
      unless updator
        t_updator_id = (account.owner ? account.owner.id : nil)
      end
    end

    attributes = self.attributes.dup.symbolize_keys.merge(:account_id => account.id,
                              :creator_id => (account.owner ? account.owner.id : nil),
                              :updator_id => t_updator_id, 
                              :domain_patterns => domain_patterns)
    attributes.merge!(:modified => options[:modified], :skip_set_modified => true) if options.has_key?(:modified)
    attributes.merge!(:uuid => options[:uuid]) if options.has_key?(:uuid)
    attributes
  end
  
  def self.to_new_from_item_version(item_version)
    attrs = item_version.attributes
    %w(id layout_id cached_parsed_template).each do |attr_name|
      attrs.delete(attr_name)
    end
    layout = self.new(attrs)
    layout
  end
  
  def content_attributes
    {
      :title => self.title,
      :body => self.body,
      :content_type => self.content_type,
      :encoding => self.encoding,
      :domain_patterns => self.domain_patterns
    }
  end

  protected
  def creator_as_text
    self.creator ? self.creator.display_name : nil
  end      

  def ensure_domain_patterns_not_empty
    self.domain_patterns = "**" if self.domain_patterns.blank?
  end

  def record_old_title
    @old_title = if self.new_record? then
                   :new
                 else
                   self.class.find(self.id).title
                 end
  end

  def update_existing_page_layouts
    returning true do
      return if @old_title == :new
      self.account.pages.update_all(["layout = ?", self.title], ["layout = ?", @old_title]) if self.rename_pages || @old_title == :new
    end
  end

  def parse_template
    Liquid::Template.parse(self.body)
  end

  # We set @parsed_template here, because #cache_parsed_template depends on it.
  def template_syntax
    begin
      @parsed_template = self.parse_template
      true
    rescue SyntaxError
      self.errors.add_to_base($!.to_s)
      false
    end
  end

  # We depend on someone setting @parsed_template before we get here.
  def cache_parsed_template
    self.cached_parsed_template = Marshal.dump(@parsed_template)
  end

  def reload_cached_parsed_template
    Marshal.load(self.cached_parsed_template)
  rescue
    logger.warn "Could not deserialize #{self.inspect}: #{$!}"
    parse_template
  end

  def guess_cache_control_directives
    return if cache_timeout_in_seconds || cache_control_directive
    if readers.empty? && writers.empty? then
      cache_control_directive = "public"
      case content_type
      when /javascript$/, /css$/
        cache_timeout_in_seconds = 2.hours
      when /xml$/
        cache_timeout_in_seconds = 1.hour
      else
        cache_timeout_in_seconds = 10.minutes
      end
    else
      cache_control_directive = "private"
      cache_timeout_in_seconds = 5.minutes
    end
  end
  
  def set_modified
    unless self.skip_set_modified
      modified = false
      last = self.versions.latest
      self.content_attributes.each_pair do |k, v|
        if self.content_attributes[k.to_sym] != last.send(k.to_sym)
          modified = true unless (self.content_attributes[k.to_sym].blank? && last.send(k.to_sym).blank?)
        end
      end if last
      self.modified = true if modified
      true
    end
  end
end
