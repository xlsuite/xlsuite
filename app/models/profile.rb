#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Profile < ActiveRecord::Base
  include XlSuite::Commentable
  
  belongs_to :account
  has_one :party, :class_name => "Party", :foreign_key => :profile_id
  belongs_to :owner, :class_name => "Party", :foreign_key => :owner_id
  
  acts_as_reportable \
    :columns => %w(honorific first_name last_name middle_name company_name display_name alias created_at updated_at average_rating claimable custom_url claimed_at),
    :map => {:addresses => :address_contact_route, :phones => :phone_contact_route, :links => :link_contact_route, :emails => :email_contact_route}

  include XlSuite::PicturesHelper
  belongs_to :avatar, :class_name => "Asset", :foreign_key => "avatar_id"
  
  after_save :update_party_available_on_domains
  after_save :update_party_action_handler_memberships

  has_many :profile_add_requests
  has_many :profile_claim_requests
  composed_of :name,    :mapping => [ %w(last_name last),
                                      %w(first_name first),
                                      %w(middle_name middle)]

  serialize :info, Hash
  
  def twitter_username=(username)
    @_twitter_changed = true
    @twitter_username = username
  end
  
  def twitter_username
    if @_twitter_changed
      @twitter_username
    else
      @_twitter_username = self.party.twitter_username if self.party
      @_twitter_username
    end
  end
  
  def set_party_twitter_username
    return true unless @_twitter_changed
    self.party.update_attribute(:twitter_username, self.twitter_username) if self.party
  end
  
  Comment::COMMENTABLES.map{|c|c.tableize.singularize}.each do |name|
    class_eval <<-EOF
      def #{name}_comment_notification=(value)
        @_#{name}_comment_notification_changed = true
        @#{name}_comment_notification = value
      end
      
      def #{name}_comment_notification
        if @_#{name}_comment_notification_changed
          @#{name}_comment_notification
        else
          @_#{name}_comment_notification = self.party.#{name}_comment_notification if self.party
          @_#{name}_comment_notification
        end
      end
    EOF
  end
  
  def set_party_comment_notification_fields
    save = false
    Comment::COMMENTABLES.map{|c|c.tableize.singularize}.each do |name|
      if instance_variable_get("@_#{name}_comment_notification_changed")
        save = true
        self.party.send("#{name}_comment_notification=", self.send("#{name}_comment_notification")) if self.party
      end
    end
    self.party.save(false) if save
    true
  end
  
  after_create :set_alias_if_blank
  after_save :set_custom_url_if_blank
  after_save :set_party_twitter_username
  after_save :set_party_comment_notification_fields

  has_many :contact_routes, :as => :routable, :order => "position", :dependent => :destroy do
    def addresses(force=false)
      @addresses = nil if force
      @addresses ||= find(:all, :conditions => ["type = ?", AddressContactRoute.name])
    end

    def emails(force=false)
      @emails = nil if force
      @emails ||= find(:all, :conditions => ["type = ?", EmailContactRoute.name])
    end

    def phones(force=false)
      @phones = nil if force
      @phones ||= find(:all, :conditions => ["type = ?", PhoneContactRoute.name])
    end

    def links(force=false)
      @links = nil if force
      @links ||= find(:all, :conditions => ["type = ?", LinkContactRoute.name])
    end
  end
  # Shortcuts for accessing ContactRoute
  has_many :phones, :class_name => "PhoneContactRoute", :as => :routable, :order => "position", :extend => XlSuite::ContactRoutesExtensions, :dependent => :destroy
  has_many :addresses, :class_name => "AddressContactRoute", :as => :routable, :order => "position", :extend => XlSuite::ContactRoutesExtensions, :dependent => :destroy
  has_many :links, :class_name => "LinkContactRoute", :as => :routable, :order => "position", :extend => XlSuite::ContactRoutesExtensions, :dependent => :destroy
  has_many :email_addresses, :class_name => "EmailContactRoute", :as => :routable, :order => "position", :extend => XlSuite::ContactRoutesExtensions, :dependent => :destroy

  acts_as_taggable
  acts_as_fulltext %w(display_name links_as_text phones_as_text addresses_as_text email_addresses_as_text tag_list position), :weight => 50 

  validates_presence_of :account_id
  validates_uniqueness_of :alias, :scope => :account_id, :if => Proc.new {|p| !p.alias.blank?}
  validates_format_of :alias, :with => /\A[-\w]+\Z/i, :message => "can contain only a-z, A-Z, 0-9, _ and -, cannot contain space(s)", :if => Proc.new {|p| !p.alias.blank?}

  validates_uniqueness_of :custom_url, :scope => :account_id, :if => Proc.new {|p| !p.custom_url.blank?}
  validates_format_of :custom_url, :with => /\A[-\w]+\Z/i, :message => "can contain only a-z, A-Z, 0-9, _ and -, cannot contain space(s)", :if => Proc.new {|p| !p.custom_url.blank?}
  
  before_save :generate_display_name
  after_save :update_party_product_category_name
    
  def gmap_query
    [self.main_address.line1, self.main_address.line2, self.main_address.city, self.main_address.state, self.main_address.zip].delete_if {|l| l.blank?}.join(', ').gsub(/#/, "")
  end
  
  def quick_description
    out = []
    if self.main_address
      out << self.main_address.line1
      out << self.main_address.line2
      out << self.main_address.city
      out << self.main_address.state
      out << self.main_address.zip 
    end
    out.delete_if(&:blank?)
    out.blank? ? "no info" : out.join(", ")
  end

  def non_address_contact_routes
    (self.phones + self.links + self.email_addresses).sort_by(&:position)
  end

  def shipping_address
    self.addresses.find(:first, :conditions => ["name = ?", "Shipping"], :order => "position DESC")
  end
  
  # TODO: change this later on after implementing the main flag for contact routes
  # at this point all other_contact_routes returns everything including the main one
  def other_addresses
    self.addresses
  end
  
  def other_emails
    self.email_addresses
  end
  
  def other_links
    self.links
  end
  
  def other_phones
    self.phones
  end

  %w(AddressContactRoute PhoneContactRoute EmailContactRoute LinkContactRoute).each do |class_name|
    singular = class_name.underscore.split("_").first
    plural = class_name.underscore.split("_").first.pluralize
    class_eval <<-EOF
      def any_#{plural}?
        !self.contact_routes.#{plural}.empty?
      end

      def main_#{singular}(force=false)
        if self.contact_routes.#{plural}(force).empty? then
          #{class_name}.new(:routable => self)
        else
          self.contact_routes.#{plural}.first
        end
      end

      # +params+ is either a single level Hash (<code>{:name => "blog", :url => "http://my.blog.com/"}</code>), or
      # a multi-level Hash (<code>{"office" => {"number" => "1-888-123-4321"}}</code>).
      #
      # If +params+ is single level, we update the Main contact route of the correct type, else
      # we update each one in turn.
      def #{singular}=(params)
        if params.values.first.kind_of?(Hash) then
          params.each_pair do |name, attrs|
            # Don't create a contact route if we have nothing to save
            next if attrs.merge(:name => nil).values.join.blank?

            name = name ? name.to_s : "Main"
            model = self.#{plural}.find_by_name(name)
            if model then
              method = model.new_record? ? :attributes= : :update_attributes
              model.send(method, attrs.merge(:name => name))
            else
              self.#{plural} << #{class_name}.new(attrs.merge(:routable => self, :name => name, :account => self.account))
            end
          end
        else
          # Turn a single level Hash into a multi-level one, so we don't have
          # to dick around and duplicate code.
          self.#{singular} = {params[:name] => params}
        end
      end
    EOF
  end
  
  def to_liquid
    ProfileDrop.new(self)
  end

  def []( attribute )
    if( attribute == 'full_name' )
      return full_name
    else
      super
    end
  end

  def full_name
    return "#{first_name} #{last_name}"
  end

  def full_name=(name)
    self.name = Name.parse(name)
  end

  def info
    read_attribute(:info) || write_attribute(:info, Hash.new)
  end
  
  def comment_approval_method
    if self.deactivate_commenting_on && (self.deactivate_commenting_on <= Date.today)
      return "no comments" 
    else
      self.read_attribute(:comment_approval_method)
    end
  end  

  def has_alias?
    !self.alias.blank?
  end  
  
  def attributes=(new_attributes, guard_protected_attributes = true)
    return if new_attributes.nil?

    attributes = new_attributes.dup
    attributes.stringify_keys!

    multi_parameter_attributes = []
    attributes = remove_attributes_protected_from_mass_assignment(attributes) if guard_protected_attributes

    attributes.each do |k, v|
      if k.include?("(")
        multi_parameter_attributes << [ k, v ]
      else
        send(:"#{k}=", v)
      end
    end

    assign_multiparameter_attributes(multi_parameter_attributes)
  end
  
  def writeable_by?(party)
    return true if party.can?(:edit_profiles)
    return true if party.owned_profiles.map(&:id).include?(self.id)
    return true if party.profile.id == self.id
    return false
  end
  
  def claimed?
    return self.profile_claim_requests.any?(&:approved_at) || self.party.confirmed?
  end
  
  def to_party_attributes
    t_attrs = {}
    Party.content_columns.map(&:name).each do |column_name|
      t_attrs.merge!(column_name => self.send(column_name)) if self.respond_to?(column_name)
    end
    t_attrs
  end
  
  def copy_routes_to_party!(party)
    self.email_addresses.each do |email_cr|
      profile_cr = email_cr.dup
      profile_cr.routable = party
      profile_cr.account = party.account
      profile_cr.save
    end
    %w(links phones addresses).each do |cr_type|
      self.send(cr_type).each do |cr|
        profile_cr = cr.dup
        profile_cr.routable = party
        profile_cr.account = party.account
        profile_cr.save!
      end
    end
    true
  end
  
  # create_first_blog method should only be called for a saved profile
  # calling it on a new record will return false immediately
  # for a profile who has at least one blog, this method will immediately return false
  def create_first_blog(domain)
    return false if self.new_record? || self.party.blogs.count > 0
    new_blog = Blog.new(:account => self.party.account)
    new_blog.owner = self.party
    new_blog.domain = domain
    new_blog.author_name = self.display_name.blank? ? "Anonymous" : self.display_name
    new_blog.title = "#{new_blog.author_name} Blog"
    new_blog.created_by = self.party
    c_label = self.display_name.blank? ? "profile-#{self.id}" : self.display_name.parameterize
    existing_blog = self.party.account.blogs.find_by_label(c_label)
    if existing_blog
      new_blog.label = UUID.random_create.to_s
    else
      new_blog.label = c_label
    end
    new_blog.save
  end
  
  def send_comment_email_notification(comment)
    if self.party && self.party.confirmed? && self.party.listing_comment_notification?
      AdminMailer.deliver_comment_notification(comment, "profile", self.party.main_email.email_address)
    end
  end
  
  def add_domain=(domain_name)
    @_add_domain = domain_name
  end
  
  def replace_domains=(string_domain_names)
    @_replace_domains = string_domain_names
  end
  
  def action_handler_labels=(string_labels)
    @_action_handler_labels = string_labels
  end
  
  def action_handler_domain_id=(number)
    @_action_handler_domain_id = number.to_i
  end
  
  def action_handler_labels
    @_action_handler_labels
  end
  
  def action_handler_domain_id
    @_action_handler_domain_id
  end
  
  protected
  
  def generate_display_name
    t_display_name = [self.company_name, self.last_name, self.first_name].reject(&:blank?).join(', ')
    if !t_display_name.blank?
      self.display_name = t_display_name
      return
    end
    if self.main_email then
      t_display_name = (self.main_email.email_address || "").split("@").first
    end
    if !t_display_name.blank?
      self.display_name = t_display_name
      return
    end
    self.display_name = "" if self.display_name.blank?
    self.display_name
  end  

  def links_as_text
    self.links.map(&:url)
  end

  def phones_as_text
    self.phones.map do |phone|
      [phone.plain_number, phone.formatted_number]
    end
  end

  def addresses_as_text
    self.addresses.map do |address|
      [address.to_url, address.full_state, address.full_country]
    end
  end
  
  def set_alias_if_blank
    return unless self.alias.blank?
    self.generate_alias
  end
  
  def generate_alias
    t_alias = self.company_name.to_s.dup
    t_alias = self.name.to_s.dup if t_alias.blank?
    return if t_alias.blank?
    t_alias.gsub!(/[^(\d\w\s)]/, "")
    t_alias.gsub!(/\s+/, " ")
    t_alias.downcase!
    t_alias.gsub!(/\s/, "_")
    c_alias, t_profile = nil, nil
    count, counter = 0, 0
    c_alias = t_alias
    loop do
      count = self.class.count(:conditions => {:alias => c_alias, :account_id => self.account.id})
      counter += 1
      if count > 0
        t_profile = self.class.find(:all, :select => "id", :conditions => {:alias => c_alias, :account_id => self.account.id}).map(&:id)
        if t_profile.size > 1
          logger.warn("You should not see this message, found the cause in Profile#generate_alias")
          return
        end
        if t_profile.first == self.id
          return
        else
          c_alias = t_alias + counter.to_s
        end
      else
        break
      end
    end
    self.update_attribute(:alias, c_alias)
  end
  
  def set_custom_url_if_blank
    return unless (self.custom_url.blank? or (!self.company_name.blank? and self.custom_url == "profile-#{self.id}"))
    self.generate_custom_url
  end
  
  def generate_custom_url
    t_custom_url = self.company_name.to_s.dup
    t_custom_url.gsub!(/[^(\d\w\s\-_)]/, "")
    t_custom_url.gsub!(/\s+/, " ")
    t_custom_url.downcase!
    t_custom_url.gsub!(/\s/, "-")
    c_custom_url, t_profile = nil, nil
    unless t_custom_url.blank?
      count, counter = 0, 0
      c_custom_url = t_custom_url
      loop do
        count = self.class.count(:conditions => {:custom_url => c_custom_url, :account_id => self.account.id})
        counter += 1
        if count > 0
          t_profile = self.class.find(:all, :select => "id", :conditions => {:custom_url => c_custom_url, :account_id => self.account.id}).map(&:id)
          if t_profile.size > 1
            logger.warn("You should not see this message, found the cause in Profile#generate_custom_url")
            return
          end
          if t_profile.first == self.id
            return
          else
            c_custom_url = t_custom_url + counter.to_s
          end
        else
          break
        end
      end
    else
      c_custom_url = "profile-#{self.id}"
    end
    self.update_attribute(:custom_url, c_custom_url)
  end

  def email_addresses_as_text
    self.email_addresses.map(&:address)
  end
  
  def update_party_available_on_domains
    t_party = self.party
    return unless t_party
    if @_add_domain || @_replace_domains
      t_party.add_domain = @_add_domain
      t_party.replace_domains = @_replace_domains
      t_party.save
    end
    true
  end
  
  def update_party_action_handler_memberships
    return if self.action_handler_labels.blank? || self.action_handler_domain_id.blank?
    t_party = self.party
    return unless t_party
    labels = self.action_handler_labels.split(",").map(&:strip)
    acct = t_party.account
    ActionHandler.find(:all, :conditions => {:label => labels, :account_id => acct.id}).each do |action_handler|
      ActionHandlerMembership.create(:action_handler => action_handler, :party => t_party, 
        :domain => acct.domains.find(self.action_handler_domain_id))
    end
    true
  end
  
  def method_missing(method, *args, &block)
    method_name = method.to_s.gsub("=", "")
    if self.class.column_names.index(method_name) 
      return super
    end
    writer_method = method.to_s.match(/=$/)
    if writer_method
      self.info.merge!(method_name => args.first)
      return true
    else
      return self.info[method_name.to_s]
    end
  end
end
