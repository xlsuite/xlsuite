#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Item < ActiveRecord::Base
  acts_as_versioned :limit => 20, :if_changed => [:title, :body, :behavior, :status, :fullslug, :domain_patterns, 
    :layout, :require_ssl, :meta_description, :meta_keywords, :no_update]
  self.non_versioned_columns << 'delta'
  
  belongs_to :account
  validates_presence_of :account_id

  include XlSuite::AccessRestrictions
  include DomainPatternsSplitter

  VALID_BEHAVIORS = %w(plain_text wysiwyg).sort.freeze # feeds, links, posts, missing, error
  BEHAVIORS_FOR_SELECT = VALID_BEHAVIORS.map {|behavior| [behavior.humanize.titleize, behavior]}.freeze
  MAXIMUM_BODY_LENGTH = 512.kilobytes

  attr_accessor :behavior_values, :skip_set_modified
  delegate :render_edit, :to => :current_behavior

  before_create :generate_random_uuid

  before_save :serialize_behavior_values
  validates_inclusion_of :behavior, :in => VALID_BEHAVIORS
  validates_presence_of :title, :if => :title_required?
  
  validates_length_of :body, :maximum => MAXIMUM_BODY_LENGTH

  def title_required?
    true
  end

  belongs_to :creator, :class_name => 'Party', :foreign_key => 'creator_id'
  belongs_to :updator, :class_name => 'Party', :foreign_key => 'updator_id'

  before_save :test_render_body

  before_save :set_modified

  validates_presence_of :domain_patterns
  before_validation :ensure_domain_patterns_not_empty

  def available_on?(domain)
    !!self.patterns.detect {|pattern| domain.matches?(pattern)}
  end

  def render_body(context=nil)
    current_behavior.render(context)
  end

  def behavior=(value)
    @behavior = @behavior_values = nil
    write_attribute(:behavior, value)
  end

  # Reload previously stored values.
  def behavior_values
    @behavior_values ||= current_behavior.deserialize
  end

  def behavior_values=(values)
    @behavior_values = values
  end
    
  def redirect?
    false
  end

  class << self
    def get_all_by_title(options={})
      with_scope(:find => {:order => "title"}) do
        find(:all, options)
      end
    end

    # Returns the list of valid behaviors.
    def valid_behaviors
      VALID_BEHAVIORS
    end

    # Returns the list of behaviors, but correctly setup for use in a #select_tag.
    def behaviors_for_select
      BEHAVIORS_FOR_SELECT
    end
  end

  def attributes_for_copy_to(account, options={})
    domain_patterns = options[:domain_patterns] || "**"
    
    t_updator_id = self.updator_id
    if t_updator_id
      updator = account.parties.find_by_id(t_updator_id)
      unless updator
        t_updator_id = (account.owner ? account.owner.id : nil)
      end
    end
    
    attributes = self.attributes.dup.merge(:account_id => account.id, :creator_id => (account.owner ? account.owner.id : nil), 
      :updator_id => t_updator_id, :domain_patterns => domain_patterns)
    attributes.merge!(:modified => options[:modified], :skip_set_modified => true) if options.has_key?(:modified)
    attributes.merge!(:uuid => options[:uuid]) if options.has_key?(:uuid)
    attributes
  end
  
  def content_attributes
    {
      :title => self.title,
      :body => self.body,
      :behavior => self.behavior,
      :status => self.status,
      :fullslug => self.fullslug,
      :layout => self.layout,
      :cache_control_directive => self.cache_control_directive
    }
  end

  protected
  def ensure_domain_patterns_not_empty
    self.domain_patterns = "**" if self.domain_patterns.blank?
  end

  # Returns this page's behavior class.
  def behavior_class
    "#{self.behavior}_behavior".classify.constantize
  end

  def current_behavior
    parsed_body = if self.cached_parsed_body.blank? then
                    nil
                  else
                    begin
                      Marshal.load(self.cached_parsed_body)
                    rescue
                      logger.warn "Could not deserialize #{self.inspect}: #{$!}"
                      Liquid::Template.parse(self.body)
                    end
                  end
    @behavior ||= self.behavior_class.new(self, parsed_body)
  end

  def serialize_behavior_values
    returning true do
      current_behavior.serialize(@behavior_values) if @behavior_values
      self.cached_parsed_body = Marshal.dump(current_behavior.parse_template(self.body))
    end
  end

  def party_display_name
    self.creator ? self.creator.display_name : nil
  end

  def test_render_body
    begin
      context = Liquid::Context.new({}, {"account" => self.account})
      self.render_body(context)
      true
    rescue SyntaxError
      self.errors.add_to_base($!.to_s)
      false
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
