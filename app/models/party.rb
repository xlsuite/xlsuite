#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

require "array_extensions"

class Party < ActiveRecord::Base
  include XlSuite::AuthenticatedUser
  include WhiteListHelper
  include XlSuite::PicturesHelper

  extend ActionView::Helpers::SanitizeHelper::ClassMethods
  include ActionView::Helpers::SanitizeHelper

  include XlSuite::AffiliateAccountHelper
  include XlSuite::AvailableOnDomain

  attr_accessor :update_effective_permissions
  attr_protected :update_effective_permissions
  
  after_save :set_effective_permissions
  after_create :generate_effective_permissions

  acts_as_taggable
  acts_as_reportable \
    :columns => %w(honorific first_name last_name middle_name company_name display_name referal forum_alias timezone created_at updated_at confirmed_at confirmed last_logged_in_at),
    :map => {:addresses => :address_contact_route, :phones => :phone_contact_route, :links => :link_contact_route, :emails => :email_contact_route}

  acts_as_fulltext %w(display_name links_as_text phones_as_text addresses_as_text email_addresses_as_text tags_as_text position), :weight => 50 

  IMMEDIATELY = 'immediately'
  DAILY = 'daily'
  WEEKLY = 'weekly'
  HONORIFICS = ["Mr.", "Mrs.", "Ms"]

  has_many :affiliates
  has_many :blogs, :foreign_key => :owner_id
  has_many :blog_posts, :foreign_key => :author_id
  has_many :created_groups, :foreign_key => :created_by_id, :class_name => "Group"
  has_many :created_listings, :foreign_key => :creator_id, :class_name => "Listing"
  
  has_many :audio_files, :source => :asset, :through => :views, :order => "views.position", :conditions => Asset::AUDIO_FILES_CONDITION
  has_many :flash_files, :source => :asset, :through => :views, :order => "views.position", :conditions => Asset::FLASH_FILES_CONDITION
  has_many :shockwave_files, :source => :asset, :through => :views, :order => "views.position", :conditions => Asset::SHOCKWAVE_FILES_CONDITION
  has_many :multimedia, :source => :asset, :through => :views, :order => "views.position", :conditions => ["views.classification=?", "multimedia"]
  has_many :other_files, :source => :asset, :through => :views, :order => "views.position", :conditions => ["views.classification=?", "other_files"]
  
  has_many :polygons, :as => :owner

  has_one :cart, :order => "updated_at DESC", :as => :invoice_to

  has_many :email_accounts
  has_many :filters
  has_many :email_labels
  
  has_and_belongs_to_many :feeds

  before_destroy {|p| p.account.owner != p }

  validates_presence_of :account_id
  belongs_to :account
  has_many :estimates, :foreign_key => :billing_customer_id, :order => 'id DESC'
  has_many :recent_estimates, :class_name => 'Estimate', :foreign_key => :billing_customer_id, :order => 'updated_at DESC'
  has_many :current_estimates, :conditions => 'updated_at BETWEEN NOW() - INTERVAL 6 MONTH AND NOW()', :order => 'updated_at DESC', :class_name => 'Estimate', :foreign_key => :billing_customer_id

  has_many :invoices, :foreign_key => :customer_id, :order => 'number DESC'

  belongs_to :referred_by, :class_name => "Party", :foreign_key => "referred_by_id"
  has_many :referrals, :class_name => "Party", :foreign_key => "referred_by_id",
      :dependent => :nullify, :order => "display_name"

  has_many :testimonials, :order => 'testified_on', :dependent => :delete_all, :foreign_key => :author_id

  has_many :attachments, :foreign_key => 'owner_id'
  has_many :available_slots, :class_name => 'PartyAvailableSlot'

  has_many :recipients
  
  # TODO remove conditions?
  has_many :emails, :through => :recipients, :order => 'received_at DESC', 
      :select => "DISTINCT emails.*", :conditions => "emails.mass_mail IS NULL"
    
  has_many                    :events, :foreign_key => 'owner_id',
                              :order => 'updated_at DESC'

  belongs_to :created_by, :class_name => "Party", :foreign_key => :created_by_id
  belongs_to :updated_by, :class_name => "Party", :foreign_key => :updated_by_id

  has_many :contact_requests, :order => "completed_at, created_at DESC", :dependent => :destroy
  has_and_belongs_to_many :received_contact_requests, :class_name => "ContactRequest", :join_table => "contact_request_recipients"

  has_many :searches, :dependent => :destroy, :order => "name ASC"
  
  has_many :imports
  has_many :assets, :foreign_key => "owner_id", :order => "title, filename"
  has_many :folders, :foreign_key => "owner_id", :order => "name"

  has_many :notes, :as => :commentable, :class_name => "Comment", :order => "created_at DESC"

  belongs_to :avatar, :class_name => "Asset", :foreign_key => "avatar_id"

  composed_of :tz, :class_name => "TZInfo::Timezone", :mapping => %w(timezone identifier)
  validates_uniqueness_of :forum_alias, :scope => :account_id, :if => Proc.new {|p| !p.forum_alias.blank?}
  validates_uniqueness_of :gigya_uid, :scope => :account_id, :if => Proc.new {|p| !p.gigya_uid.blank?}

  serialize :info, Hash
  
  has_and_belongs_to_many :product_categories
  belongs_to :profile, :dependent => :destroy
  has_many :owned_profiles, :class_name => "Profile", :foreign_key => :owner_id
  
  has_one :api_key, :dependent => :delete

  has_many :expiring_items, :class_name => "ExpiringPartyItem", :foreign_key => :party_id
  has_many :expiring_blogs, :through => :expiring_items, :source => :item, :source_type => "Blog"
  has_many :expiring_assets, :through => :expiring_items, :source => :item, :source_type => "Asset"

  has_many :products, :foreign_key => :owner_id

  has_many :domain_points, :class_name => "PartyDomainPoint"
  has_many :domain_monthly_points, :class_name => "PartyDomainMonthlyPoint"
  
  after_destroy :set_blog_posts_author_to_account_owner

  def granted_products
    group_ids = self.groups.map(&:id)
    return [] if group_ids.blank?
    self.account.products.find(:all, :joins => "INNER JOIN product_grants g ON g.product_id = products.id", :conditions => "g.object_id IN (#{group_ids.join(',')})")
  end
  
  def granted_blogs
    products = self.granted_products
    return [] if products.empty?
    self.account.blogs.find(:all, :joins => "INNER JOIN product_items ON blogs.id = product_items.item_id AND product_items.item_type = 'Blog'", :conditions => "product_items.product_id IN (#{self.granted_products.map(&:id).join(',')})")
  end
  
  def granted_assets
    products = self.granted_products
    return [] if products.empty?
    self.account.assets.find(:all, :joins => "INNER JOIN product_items ON assets.id = product_items.item_id AND product_items.item_type = 'Asset'", :conditions => "product_items.product_id IN (#{self.granted_products.map(&:id).join(',')})")
  end
  
  def granted_groups
    products = self.granted_products
    return [] if products.empty?
    self.account.groups.find(:all, :joins => "INNER JOIN product_items ON groups.id = product_items.item_id AND product_items.item_type = 'Group'", :conditions => "product_items.product_id IN (#{self.granted_products.map(&:id).join(',')})")
  end

  def deliver_signup_confirmation_email(options)
    begin
      AdminMailer.deliver_signup_confirmation_email(:route => self.main_email(true),
          :confirmation_url => options[:confirmation_url],
          :confirmation_token => options[:confirmation_token])
    rescue
      errored = (options[:errored]||0)+1
      if errored > 30
        raise
      else
        MethodCallbackFuture.create!(:models => [self], :account => self.account, :method => :deliver_signup_confirmation_email, 
          :scheduled_at => errored.minutes.from_now,
          :params => {:confirmation_url => options[:confirmation_url], 
                      :confirmation_token => options[:confirmation_token], :errored => errored})
      end
    end
  end

  def grant_api_access!
    return self.api_key unless self.api_key.nil?
    returning(self.build_api_key) do |key|
      key.save!
    end
  end

  def revoke_api_access!
    self.api_key.nil? ? nil : self.api_key.destroy
  end

  def copy_contact_routes_to_profile!
    return false unless self.profile
    self.copy_routes_to(self.profile.reload)
    true
  end
  
  def to_new_profile
    profile = Profile.new
    profile.account = self.account
    Profile.content_columns.map(&:name).each do |column_name|
      profile.send("#{column_name}=", self.send(column_name)) if self.respond_to?(column_name)
    end
    profile.tag_list = self.tag_list
    profile.avatar = self.avatar
    profile
  end
  
  def info
    read_attribute(:info) || write_attribute(:info, Hash.new)
  end
  
  # Addresses, Phones, E-Mail addresses and Links
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
  has_many :phones, :class_name => "PhoneContactRoute", :as => :routable, :order => "position", :extend => XlSuite::ContactRoutesExtensions
  has_many :addresses, :class_name => "AddressContactRoute", :as => :routable, :order => "position", :extend => XlSuite::ContactRoutesExtensions
  has_many :links, :class_name => "LinkContactRoute", :as => :routable, :order => "position", :extend => XlSuite::ContactRoutesExtensions
  has_many :email_addresses, :class_name => "EmailContactRoute", :as => :routable, :order => "position", :extend => XlSuite::ContactRoutesExtensions

  def non_address_contact_routes
    (self.phones + self.links + self.email_addresses).sort_by(&:position)
  end

  def shipping_address
    self.addresses.find(:first, :conditions => ["name = ?", "Shipping"], :order => "position DESC")
  end
  
  def gmap_query
    [self.main_address.line1, self.main_address.line2, self.main_address.city, self.main_address.state, self.main_address.zip].delete_if {|l| l.blank?}.join(', ')
  end
  
  def quick_description
    out = []
    if self.main_address
      out << self.main_address.line1
      out << self.main_address.line2
      out << self.main_address.city
      out << self.main_address.state
      out << self.main_address.country
      out << self.main_address.zip 
    end
    out.delete_if(&:blank?)
    out.blank? ? "no info" : out.join(", ")
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

  def recent_events
    self.events.find(:all, :limit => 20)
  end

  has_many :interests, :dependent => :destroy
  has_many :listings, :through => :interests
  
  has_many :posts, :class_name => 'ForumPost', :foreign_key => 'user_id'

  # Security / Permission management
  has_many :permission_grants, :as => :assignee, :dependent => :delete_all
  has_many :permissions, :through => :permission_grants, :source => :subject, :source_type => "Permission", :order => "permissions.name"
  
  has_many :permission_denials, :as => :assignee, :dependent => :delete_all
  has_many :denied_permissions, :through => :permission_denials, :source => :subject, :source_type => "Permission", :order => "permissions.name"
  
  has_many :roles, :through => :permission_grants, :source => :subject, :source_type => "Role", :order => "roles.name"
  
  has_many :memberships
  has_many :groups, :through => :memberships, :order => "name"
  has_and_belongs_to_many :effective_permissions, :join_table => :effective_permissions, :foreign_key => "party_id", :association_foreign_key => "permission_id", :class_name => "Permission", :order => "name"

  def recent_posts(count=5)
    self.posts.find(:all, :limit => count, :order => "updated_at DESC")
  end

  # TODO: Rename to readable_by_edit_own_contacts_only?, and alias_method_chain :readable_by, :edit_own_contacts_only.
  def readable_by?(party)
    return false unless party.can?(:edit_own_account, :edit_own_contacts_only, :view_own_contacts_only, :edit_party, :view_party, :any => true)
    # Always allow reading by self
    return true if party.can?(:edit_own_account) && party.id == self.id
    # Allow reading our own contacts
    return true if party.can?(:edit_own_contacts_only, :view_own_contacts_only) && self.created_by_id == party.id
    # Else, allow reading by editors
    party.can?(:edit_party)
  end

  # TODO: Rename to writeable_by_edit_own_contacts_only?, and alias_method_chain :writeable_by, :edit_own_contacts_only.
  def writeable_by?(party)
    return false unless party.can?(:edit_own_account, :edit_own_contacts_only, :edit_party, :any => true)
    # Always allow writing by self
    return true if party.can?(:edit_own_account) && party.id == self.id
    # Allow writing our own contacts
    return true if party.can?(:edit_own_contacts_only) && self.created_by_id == party.id
    # Else, allow writing by editors
    party.can?(:edit_party)
  end

  def to_xml(options={})
    options[:indent] ||= 2
    xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])
    xml.instruct! unless options[:skip_instruct]
    xml.party(:id => self.dom_id) do
      xml.tag! "company-name", self.company_name
      name.to_xml(options)
      xml.tag! "phones", self.phones.map(&:main_identifier).join(", ")
      xml.tag! "links", self.links.map(&:main_identifier).join(", ")
      xml.tag! "email-addresses", self.email_addresses.map(&:main_identifier).join(", ")
      xml.tag! "addresses", self.addresses.map(&:to_s).join("\n")
    end
  end

  def set_name(value)
    case value
    when Name
      self.name = name
    when String
      self.name = Name.parse(value)
    when NilClass
      self.name = Name.parse("")
    else
      self.set_name(value.to_s)
    end
  end

  def permission_ids
    self.permissions.map(&:id)
  end

  def permission_ids=(new_ids)
    new_ids = (new_ids || []).reject(&:blank?)
    old_ids = self.permission_ids

    self.transaction do
      PermissionGrant.delete_all({:subject_type => "Permission", :subject_id => old_ids - new_ids, :assignee_id => self.id, :assignee_type => self.class.name }) unless old_ids.empty?
      (new_ids - old_ids).each do |permission_id|
        self.permission_grants.create!(:subject_type => "Permission", :subject_id => permission_id)
      end
    end
  end

  Roles = %w(customer installer supplier staff candidate client peer team commercial residential)

  Roles.each do |role|
    define_method("#{role}?") do
      self.tag_list[role] ? true : false
    end
  end

  ClimbingExperiences = ['Veteran', 'Some', 'None'].to_selection_list.freeze
  RopeWorkExperiences = ['Pro', 'Some', 'None'].to_selection_list.freeze
  BooleanChoices = [['Yes', 1], ['No', 0]]
  VehicleTypes = ['None', 'Van/Truck', 'Car'].to_selection_list.freeze

  OrderTypes = %w(Wholesaler Dropshipper Unknown).to_selection_list.freeze
  ValidOrderTypes  = OrderTypes.map {|otype| otype.last}.freeze
  validates_inclusion_of  :order_type, :in => ValidOrderTypes, :if => :supplier?

  InterestMailingFrequencies = [['Never', nil], ['Immediately', IMMEDIATELY], ['Daily', DAILY], ['Weekly', WEEKLY]]

  composed_of :name,    :mapping => [ %w(last_name last),
                                      %w(first_name first),
                                      %w(middle_name middle)]
                                      
  before_validation :set_default_order_type
  # WE DONT NEED THIS ANYMORE SINCE WE HAVE generate_effective_permissions, THINK ABOUT THIS SOME MORE
  # DEFAULT PERMISSION IS ATTACHED on generate_effective_permissions
  #after_save :update_auto_permissions
  before_save :strip_names
  before_save :generate_display_name

  def []( attribute )
    if( attribute == 'full_name' )
      return full_name
    else
      super
    end
  end

  def self.find_available_installers
    self.find_tagged_with(:all => 'installer', :order => 'display_name')
  end

  def self.find_staff_or_installer
    self.find_tagged_with(:any => 'staff installer', :order => 'display_name')
  end

  def mail_folder(name)
    tags = Tag.parse(name.to_s)
    emails = self.recipients.find_tagged_with(:all => tags).map(&:email)
    emails += Email.find_tagged_with(:all => tags, :conditions => ['sender_id = ?', self.id])

    emails.uniq
  end

  def client?
    self.customer?
  end

  def full_name
    return "#{first_name} #{last_name}"
  end

  def self.find_by_full_name(full_name, options={})
    names = full_name.split(" ")
    with_scope(:find => {:conditions => ["first_name = ? and last_name = ?", names[0], names[1]]}) do
      self.find(:first, options)
    end
  end

  def human_website_url
    self.website_url.gsub(%r{^[-a-z]+://}i, '').gsub(%r{/$}, '')
  end

  def website_url=(url)
    write_attribute(:website_url, if url.blank? then
                                    nil
                                  elsif url[/^https?|ftp/] then
                                    url
                                  else
                                    'http://' + url
                                  end)
  end

  def biography=(text)
    write_attribute(:biography, white_list(text))
  end

  def signature=(text)
    write_attribute(:signature, white_list(text))
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

  def unread_mail
    Email.find(:all, :select => 'emails.*', :joins => 'INNER JOIN recipients ON recipients.email_id = emails.id',
              :conditions => ['recipients.party_id = ? AND recipients.read_at IS NULL', self.id])
  end

  def to_liquid
    PartyDrop.new(self)
  end

  def to_s
    self.display_name
  end

  def full_name=(name)
    self.name = Name.parse(name)
  end

  def birthdate=(value)
    write_attribute(:birthdate, self.parse_local_date(value)) if value
  end

  def parse_local_date(str)
    date = Chronic.parse(str).to_date
    self.tz.local_to_utc(date.to_time.at_midnight).to_date
  end

  def parse_local_time(str)
    self.parse_local_datetime(str)
  end

  def parse_local_datetime(str)
    self.tz.local_to_utc(Chronic.parse(str))
  end

  def format_utc_date(dt)
    format_utc_datetime(dt, self.date_format, nil)
  end

  def format_utc_time(dt)
    format_utc_datetime(dt, nil, self.time_format)
  end

  def format_utc_datetime(dt, date_format=self.date_format, time_format=self.time_format)
    local_time = dt.to_time
    format_str = [date_format, time_format].compact.join(" ")
    local_time.strftime(format_str)
  end

  alias_method :format_utc_date_time, :format_utc_datetime

  def self.for_select(options={})
    conditions, values = options_to_array_and_hash(options)

    conditions << 'LENGTH(display_name)'
    conditions << 'archived_at IS NULL'

    options.merge!(
      :conditions => [conditions.join(' AND '), values].flatten,
      :order => "display_name")

    self.find(:all, options)
  end

  def self.find_all_by_display_name_like(name, options={})
    self.with_scope(:find => {:conditions => ["display_name LIKE ?", "%#{name}%"]}) do
      Party.find(:all, options.reverse_merge(:order => "display_name"))
    end
  end

  def self.find_by_phone(number)
    phone = PhoneContactRoute.find_by_number(number)
    phone ? phone.routable : nil
  end

  def archive!
    self.update_attribute(:archived_at, Time.now)
    self.pictures.each {|pp| pp.destroy }
    self.freeze
  end

  alias_method :archive, :archive!

  def unarchive!
    self.update_attribute(:archived_at, nil)
  end

  def archived?
    !!self.archived_at
  end

  def busy?(*args)
    day, time = PartyAvailableSlot.convert_to_day_and_time(*args)
    0 == PartyAvailableSlot.count(:id,
      :conditions => ['party_id = :party AND day_name = :day AND start_time = :time',
      { :party => self.id,
        :day => PartyAvailableSlot.symbol_or_date_to_day_name(day),
        :time => time}])
  end

  def free?(*args)
    !busy?(*args)
  end

  def free(day, times)
    day = PartyAvailableSlot.symbol_or_date_to_day_name(day)
    self.transaction do
      (times.respond_to?(:each) ? times : [times]).each do |time|
        next if free?(day, time)
        self.available_slots.create(:day_name => day.to_s, :start_time => time)
      end
    end
  end

  def block(day, times)
    day = PartyAvailableSlot.symbol_or_date_to_day_name(day)
    PartyAvailableSlot.delete_all(
      ['party_id = :party AND day_name = :day AND start_time IN (:times)',
      { :party => self.id, :day => day.to_s,
        :times => (times.respond_to?(:each) ? times : [times])}])
  end

  def self.filter_name(filters)
    name = Array.new
    name << "Party is a #{filters[:type].inspect}" unless filters[:type].blank?

    unless filters[:name].blank?
      case filters[:field]
      when /name/i
        name << "Names match #{filters[:name].inspect}"

      when /tag.*any/i
        name << "Tagged any #{[filters[:name]].flatten.join(' ').inspect}"

      when /tag.*all/i
        name << "Tagged all #{[filters[:name]].flatten.join(' ').inspect}"

      when /e-mail/i
        name << "E-Mail matches #{filters[:name].inspect}"

      when /referal/i
        name << "Referal matches #{filters[:name].inspect}"

      when /address/i
        name << "Address match #{filters[:name].inspect}"

      when /city/i
        name << "City matches #{filters[:name].inspect}"

      when /state/i
        name << "State matches #{filters[:name].inspect}"

      when /country/i
        name << "Country matches #{filters[:name].inspect}"

      when /zip/i
        name << "Zip/Postal Code matches #{filters[:name].inspect}"

      when /phone/i
        name << "Phone matches #{filters[:name].inspect}"
      end
    end

    name.join(' AND ')
  end

  def self.account_scope(account)
    raise ArgumentError, "No block given" unless block_given?
    with_scope(:find => {:conditions => {:account_id => account.id}}, 
        :create => {:account_id => account.id}) do
      yield
    end
  end

  def self.find_by_filters(filters, options={})
    options = {:per_page => 30}.merge(options)

    conditions = ['parties.archived_at IS NULL']
    values = []
    joins = []
    fields = []
    tags = Hash.new
    anywhere = false

    conditions << "parties.#{filters[:type].downcase.to_sym} = 1" unless filters[:type].blank?

    unless filters[:name].blank?
      case filters[:field]
      when /name/i
        fields = %w(display_name).map {|f| "parties.#{f}"}
        anywhere = true

      when /tag.*any/i
        tags[:any] = filters[:name]

      when /tag.*all/i
        tags[:all] = filters[:name]

      when /e-mail/i
        fields = %w(contact_routes.email_address)
        joins << " INNER JOIN contact_routes ON contact_routes.type = '#{EmailContactRoute.name}' AND contact_routes.routable_id = parties.id AND contact_routes.routable_type = 'Party'"
        anywhere = true

      when /referal/i
        fields = %w(referal).map {|f| "parties.#{f}"}
        anywhere = true

      when /address/i
        fields = %w(line1 line2 line3 city state zip country).map {|f| "contact_routes.#{f}"}
        joins << " INNER JOIN contact_routes ON contact_routes.type = '#{AddressContactRoute.name}' AND contact_routes.routable_id = parties.id AND contact_routes.routable_type = 'Party'"
        anywhere = true

      when /city/i
        fields = %w(city).map {|f| "contact_routes.#{f}"}
        joins << " INNER JOIN contact_routes ON contact_routes.type = '#{AddressContactRoute.name}' AND contact_routes.routable_id = parties.id AND contact_routes.routable_type = 'Party'"
        anywhere = true

      when /state/i
        fields = %w(state).map {|f| "contact_routes.#{f}"}
        joins << " INNER JOIN contact_routes ON contact_routes.type = '#{AddressContactRoute.name}' AND contact_routes.routable_id = parties.id AND contact_routes.routable_type = 'Party'"

      when /country/i
        fields = %w(country).map {|f| "contact_routes.#{f}"}
        joins << " INNER JOIN contact_routes ON contact_routes.type = '#{AddressContactRoute.name}' AND contact_routes.routable_id = parties.id AND contact_routes.routable_type = 'Party'"

      when /zip/i
        fields = %w(zip).map {|f| "contact_routes.#{f}"}
        joins << " INNER JOIN contact_routes ON contact_routes.type = '#{AddressContactRoute.name}' AND contact_routes.routable_id = parties.id AND contact_routes.routable_type = 'Party'"

      when /phone/i
        fields = %w(contact_routes.number)
        joins << " INNER JOIN contact_routes ON contact_routes.type = '#{PhoneContactRoute.name}' AND contact_routes.routable_id = parties.id AND contact_routes.routable_type = 'Party'"
        anywhere = true
      end

      unless fields.empty? then
        cond = %Q((#{fields.map {|field| "LOWER(#{field}) LIKE ?"}.join(' OR ')}))
        conds = []
        filters[:name].each do |name|
          value = "#{name.downcase}%"
          value = "%#{value}" if anywhere

          conds << cond
          fields.size.times { values << value }
        end

        conditions << "(#{conds.join(' OR ')})"
      end
    end

    join_clause = joins.join(' ')
    conditions = [conditions.first, "NOT (#{conditions[1..-1].join(' AND ')})"] if filters[:exclude] and conditions.size > 1
    where_clause = (conditions.empty? ? nil : [conditions.join(' AND '), values].flatten)
    order_clause = %q(parties.display_name, parties.updated_at)

    qoptions = Hash.new
    qoptions[:select]     = "DISTINCT #{options[:select] ? options[:select] : 'parties.*'}"
    qoptions[:conditions] = where_clause
    qoptions[:order]      = order_clause
    if options[:per_page] then
      qoptions[:offset]   = ((options[:page] ? options[:page].to_i : 1) - 1) * options[:per_page]
      qoptions[:limit]    = options[:per_page]
    end

    case
    when tags[:any]
      qoptions[:any] = Tag.parse(tags[:any])
      return [self.find_tagged_with(qoptions), self.count_tagged_with({:any => qoptions[:any]})]
    when tags[:all]
      qoptions[:all] = Tag.parse(tags[:all])
      return [self.find_tagged_with(qoptions), self.count_tagged_with({:all => qoptions[:all]})]
    else
      qoptions[:joins] = join_clause
      return [Party.find(:all, qoptions), Party.count('parties.id', :conditions => where_clause, :joins => join_clause)]
    end
  end

  def self.find_by_name(name_part, options={})
    conditions = options[:conditions] ? [options[:conditions]] : []
    values = {}
    order_clause = options[:order] || %q(parties.display_name, parties.updated_at)

    name_conds = []
    %w(company_name last_name first_name).each do |f|
      name_conds << "LOWER(#{f}) LIKE :name_part"
    end

    conditions << "(#{name_conds.join(' OR ')})"
    values[:name_part] = "%#{name_part.to_s.downcase}%"

    self.find(:all, :conditions => [conditions.join(' AND '), values],
                    :order => order_clause)
  end

  def unpaid_invoices
    self.invoices.select do |invoice|
      invoice.balance > Money.empty
    end
  end

  def paid_invoices
    self.invoices.select do |invoice|
      invoice.balance == Money.empty
    end
  end

  class << self
    def get_all_by_display_name(q, options={})
      with_scope(:find => {:conditions => ["display_name LIKE ?", "%#{q}%"]}) do
        find_all_by_name(options)
      end
    end

    def count_all_by_display_name(q)
      with_scope(:find => {:conditions => ["display_name LIKE ?", "%#{q}%"]}) do
        count
      end
    end

    def find_all_by_name(options={})
      find(:all, options.reverse_merge(:order => "CONCAT_WS(' ', last_name, first_name, middle_name, company_name)"))
    end

    def find_by_email_address(email_address)
      return nil if email_address.blank?
      route = EmailContactRoute.find_by_address_and_routable_type(email_address, "Party")
      route ? route.routable : nil
    end

    def find_by_email_address!(email_address)
      party = self.find_by_email_address(email_address)
      raise ActiveRecord::RecordNotFound unless party
      party
    end
    
    def find_by_account_and_email_address(account, email_address)
      return nil if [account, email_address].any?(&:blank?)
      route = account.email_contact_routes.find_by_email_address_and_routable_type(email_address, "Party")
      route ? route.routable : nil
    end
    
    def find_by_account_and_email_address!(account, email_address)
      party = self.find_by_account_and_email_address(account, email_address)
      raise ActiveRecord::RecordNotFound unless party
      party
    end

    def count_with_archived_scope(*args)
      with_archived_scope do
        count_without_archived_scope(*args)
      end
    end

    def find_with_archived_scope(*args)
      with_archived_scope do
        find_without_archived_scope(*args)
      end
    end

    unless Party.respond_to?(:find_without_archived_scope) then
      alias_method_chain :find, :archived_scope
      alias_method_chain :count, :archived_scope
    end

    def with_archived_scope(&block)
      raise "Called without a block" unless block_given?
      with_scope(:find => {:conditions => "archived_at IS NULL"}) do
        yield
      end
    end

    def authenticate_with_account_email_and_password!(account, *args)
      self.with_scope(
          :find => {:conditions => ["parties.account_id = ? and confirmed_at IS NOT NULL", account.id]},
          :create => {:account => account}) do
        EmailContactRoute.with_scope(
            :find => {:conditions => ["contact_routes.account_id = ? AND contact_routes.routable_type = 'Party' ", account.id]},
            :create => {:account => account}) do
          authenticate_with_email_and_password!(*args)
        end
      end
    end

    private :authenticate_with_email_and_password!
  end

  def reset_password(domain_name)
    Party.transaction do
      new_password = self.randomize_password!
      PartyNotification.deliver_password_reset(
          :party => self, :site_name => domain_name,
          :username => self.main_email.address,
          :password => new_password) if self.main_email
      self.confirm!
    end
  end

  def main_identifier
    self.display_name
  end

  def copy_to_account(target, account)
    self.class.name.constantize.content_columns.map(&:name).each do |column|
      next if !target.send(column).blank?
      target.send("#{column}=", self.send(column))
    end
    target.tag_list = target.tag_list << " #{self.tag_list}"
    target.account = account
    target.token = nil
    target.generate_random_uuid
    target.save!
    
    copy_routes_to(target, false)
  end

  def copy_to(target)
    self.class.name.constantize.content_columns.map(&:name).each do |column|
      next if !target.send(column).blank?
      target.send("#{column}=", self.send(column))
    end
    target.tag_list = target.tag_list << " #{self.tag_list}"
    target.save!
    
    self.groups.each do |g|
      target.groups << g unless target.groups.include?(g)
    end
    
    copy_routes_to(target)
  end
  
  def copy_routes_to(target, overwrite_target_routes=true)
    self.email_addresses.each do |addr|      
      foreign_addr = target.email_addresses.detect {|e| e.name == addr.name} if overwrite_target_routes
      foreign_addr ||= target.email_addresses.build(:name => addr.name)
      addr.copy_to(foreign_addr)
    end

    self.addresses.each do |addr|
      foreign_addr = target.addresses.detect {|e| e.name == addr.name} if overwrite_target_routes
      foreign_addr ||= target.addresses.build(:name => addr.name)
      addr.copy_to(foreign_addr)
    end

    self.phones.each do |phone|
      foreign_phone = target.phones.detect {|e| e.name == phone.name} if overwrite_target_routes
      foreign_phone ||= target.phones.build(:name => phone.name)
      phone.copy_to(foreign_phone)
    end

    self.links.each do |link|
      foreign_link = target.links.detect {|e| e.name == link.name} if overwrite_target_routes
      foreign_link ||= target.links.build(:name => link.name)
      link.copy_to(foreign_link)
    end
  end
  
  def find_unread_emails(options={})
    email_ids = Party.connection.select_values("SELECT DISTINCT email_id FROM recipients WHERE recipients.party_id = #{self.id} AND recipients.read_at IS NULL")
    email_ids.reject!{|e| e.blank?}
    return [] if email_ids.empty?
    options.reverse_merge!(:limit => 5, :conditions => "emails.received_at IS NOT NULL AND emails.id IN (#{email_ids.join(',')})")
    Email.find(:all, options)
  end
  
  def find_sent_and_read_emails(options={})
    email_ids = Party.connection.select_values("SELECT DISTINCT email_id FROM recipients WHERE recipients.party_id = #{self.id} AND recipients.read_at IS NOT NULL")
    email_ids.reject!{|e| e.blank?}
    return [] if email_ids.empty?
    options.reverse_merge!(:limit => 5, 
      :conditions => "(emails.sent_at IS NOT NULL OR emails.received_at IS NOT NULL) AND emails.id IN (#{email_ids.join(',')})",
      :order => 'CONCAT_WS("", emails.sent_at, emails.received_at) DESC')
    Email.find(:all, options)
  end
  
  def count_unread_emails
    #self.emails.count("distinct(emails.id)", :conditions => "read_at IS NULL AND emails.received_at IS NOT NULL")
    email_ids = self.recipients.find(:all, :select => 'DISTINCT recipients.email_id', :conditions => "recipients.email_id IS NOT NULL AND recipients.read_at IS NULL").map(&:email_id);
    email_ids.reject!{|e| e.blank?}
    return 0 if email_ids.empty?
    Email.count(:conditions => "emails.received_at IS NOT NULL AND emails.id IN (#{email_ids.join(',')})")
  end
  
  # TODO implement later please
  #def count_total_inbox
  #  self.recipients.count(:all, :conditions => "type <> 'Sender'")
  #end
  
  def has_access_to_email?(email)
    %w(sender tos bccs ccs).each do |relation|
      for email_address in self.email_addresses.map(&:email_address)
        for party in email.send(relation).to_a.map(&:party)
          return true if party.email_addresses.map(&:email_address).join(",").index(email_address) || email.belongs_to_party(party)
        end
      end
    end
    false
  end
  
  def find_inbox_emails(query_params, options={})
    options.merge!(:conditions => 'received_at IS NOT NULL', :order => "received_at DESC")
    self.emails.search(query_params, options)
  end

  def count_inbox_emails(query_params)
    self.emails.count_results(query_params, :conditions => 'received_at IS NOT NULL')
  end
  
  def find_outbox_emails(query_params, options={})
    email_ids = self.find_email_ids(["recipients.type='Sender'"])
    return [] if email_ids.empty?
    mass_email_cond = nil
    mass_email_cond = " OR (emails.mass_mail = 1 AND emails.account_id = #{self.account_id})" if self.can?(:edit_all_mailings)
    options.merge!(:conditions => "(emails.id IN (#{email_ids.join(',')})#{mass_email_cond}) AND emails.released_at IS NOT NULL AND emails.sent_at IS NULL", :order => "emails.released_at DESC")
    Email.search(query_params, options)
    #self.emails.find(:all, :conditions => 'released_at IS NOT NULL AND emails.sent_at IS NULL', :order => 'released_at DESC')
  end
  
  def count_outbox_emails(query_params)
    email_ids = self.find_email_ids(["recipients.type='Sender'"])
    return 0 if email_ids.empty?
    mass_email_cond = nil
    mass_email_cond = " OR (emails.mass_mail = 1 AND emails.account_id = #{self.account_id})" if self.can?(:edit_all_mailings)
    Email.count_results(query_params, :conditions => "(emails.id IN (#{email_ids.join(',')})#{mass_email_cond}) AND emails.released_at IS NOT NULL AND emails.sent_at IS NULL")
  end
  
  def find_draft_emails(query_params, options={})
    email_ids = self.find_email_ids
    return [] if email_ids.empty?
    mass_email_cond = nil
    mass_email_cond = " OR (emails.mass_mail = 1 AND emails.account_id = #{self.account_id})" if self.can?(:edit_all_mailings)
    options.merge!(:conditions => "(emails.id IN (#{email_ids.join(',')})#{mass_email_cond}) AND emails.released_at IS NULL AND emails.sent_at IS NULL AND emails.received_at IS NULL")
    Email.search(query_params, options)
    #self.emails.find(:all, :conditions => 'emails.released_at IS NULL AND emails.sent_at IS NULL AND emails.received_at IS NULL', :order => "created_at DESC")
  end

  def count_draft_emails(query_params)
    email_ids = self.find_email_ids
    return 0 if email_ids.empty?
    mass_email_cond = nil
    mass_email_cond = " OR (emails.mass_mail = 1 AND emails.account_id = #{self.account_id})" if self.can?(:edit_all_mailings)
    Email.count_results(query_params, :conditions => "(emails.id IN (#{email_ids.join(',')})#{mass_email_cond}) AND emails.released_at IS NULL AND emails.sent_at IS NULL AND emails.received_at IS NULL")
  end
  
  # TODO: DOING IT LIKE THIS WILL SHOW ONLY THE EMAIL OBJECT THAT CONTAINS THE MASS EMAIL TEMPLATE
  # should we display all generated mass email instead?
  def find_sent_emails(query_params, options={})
    email_ids = self.find_email_ids(["recipients.type='Sender'"])
    return [] if email_ids.empty?
    mass_email_cond = nil
    mass_email_cond = " OR (emails.mass_mail = 1 AND emails.account_id = #{self.account_id})" if self.can?(:edit_all_mailings)
    options.merge!(:conditions => "emails.account_id=#{self.account.id} AND (emails.id IN (#{email_ids.join(',')})#{mass_email_cond}) AND emails.sent_at IS NOT NULL", :order => "emails.sent_at DESC")
    Email.search(query_params, options)
    #self.emails.find(:all, :conditions => 'emails.sent_at IS NOT NULL', :order => "sent_at DESC")
  end

  def count_sent_emails(query_params)
    email_ids = self.find_email_ids(["recipients.type='Sender'"])
    return 0 if email_ids.empty?
    mass_email_cond = nil
    mass_email_cond = " OR (emails.mass_mail = 1 AND emails.account_id = #{self.account_id})" if self.can?(:edit_all_mailings)
    Email.count_results(query_params, :conditions => "emails.account_id=#{self.account.id} AND (emails.id IN (#{email_ids.join(',')})#{mass_email_cond}) AND emails.sent_at IS NOT NULL")
  end

  def find_email_ids(conditions=[], orders=[])
    return [] if self.new_record?
    conditions << "party_id = #{self.id}"
    order_clause = nil
    unless orders.empty?
      order_clause = " ORDER BY " + orders.join(",")
    end
    Party.connection.select_values("SELECT DISTINCT recipients.email_id FROM recipients WHERE #{conditions.join(' AND ')}#{order_clause}").reject(&:blank?)
  end
    
  has_many :mass_emails, :through => :recipients, :order => 'received_at DESC', :conditions => "recipients.type = 'Sender' AND emails.mass_mail = 1",
      :select => "DISTINCT emails.*", :source => 'email', :class_name => "Email" do
    def find_drafts
      find(:all, :order => "created_at DESC",
        :conditions => "emails.released_at IS NULL AND emails.sent_at IS NULL AND emails.received_at IS NULL")
    end
    
    def find_outbox
      find(:all, :conditions => 'emails.released_at IS NOT NULL AND emails.sent_at IS NULL', :order => 'released_at DESC')
    end
    
    # this method returns a collection of mass recipients object
    def find_sent
      sent_mass_recipients = []
      find(:all).each do |mass_email|
        sent_mass_recipients << mass_email.mass_recipients.find(:all, :conditions => "sent_at IS NOT NULL")
      end
      sent_mass_recipients.flatten!
      sent_mass_recipients = sent_mass_recipients.sort_by {|e| e[:sent_at]}
      sent_mass_recipients.reverse
    end
  end

  class << self
    def email_address_to_report_sql(line, sql)
      if line.display_only?
        sql[:select] << "(SELECT cr_email.email_address FROM contact_routes cr_email WHERE cr_email.routable_type = 'Party' AND cr_email.routable_id = parties.id AND cr_email.type = 'EmailContactRoute' ORDER BY position LIMIT 1) email_address"
        sql[:order] << "email_address #{line.order}" if line.order =~ /asc|desc/i
      else
        sql[:select] << "cr_email.email_address email_address"
        sql[:joins] << [join_on_contact_routes("cr_email")]
      end
      line.add_conditions!(sql, "cr_email.email_address", "email_address")
    end

    def address_to_report_sql(line, sql)
      if line.display_only?
        sql[:select] << "(SELECT CONCAT_WS(', ', cr_address.line1, cr_address.line2, cr_address.line3, cr_address.city, cr_address.state, \
          cr_address.zip, cr_address.country) \
          FROM contact_routes cr_email WHERE cr_email.routable_type = 'Party' AND cr_email.routable_id = parties.id AND cr_email.type = 'EmailContactRoute' ORDER BY position LIMIT 1) email_address"
        sql[:order] << "email_address #{line.order}" if line.order =~ /asc|desc/i
      else
        sql[:select] << "CONCAT_WS(', ', cr_address.line1, cr_address.line2, cr_address.line3, cr_address.city, cr_address.state, \
          cr_address.zip, cr_address.country) AS address"
        sql[:joins] << [join_on_contact_routes("cr_address")] 
      end
      line.add_conditions!(sql, "CONCAT_WS(', ', cr_address.line1, cr_address.line2, cr_address.line3, cr_address.city, cr_address.state, \
          cr_address.zip, cr_address.country)", "address")
    end
    
    def city_to_report_sql(line, sql)
      route_attr_to_report_sql(AddressContactRoute, :cr_address, :city, :city, line, sql)
    end
    
    def state_to_report_sql(line, sql)
      route_attr_to_report_sql(AddressContactRoute, :cr_address, :state, :state, line, sql)
    end
    
    def postal_code_to_report_sql(line, sql)
      route_attr_to_report_sql(AddressContactRoute, :cr_address, :zip, :zip, line, sql)
    end
    
    def country_to_report_sql(line, sql)
      route_attr_to_report_sql(AddressContactRoute, :cr_address, :country, :country, line, sql)
    end
    
    def phone_to_report_sql(line, sql)
      if line.display_only?
        sql[:select] << "(SELECT CONCAT_WS(' ext:', cr_phone.number, cr_phone.extension) \
          FROM contact_routes cr_phone WHERE cr_phone.routable_type = 'Party' AND cr_phone.routable_id = parties.id AND cr_phone.type = 'PhoneContactRoute' ORDER BY position LIMIT 1) phone"
        sql[:order] << "phone #{line.order}" if line.order =~ /asc|desc/i
      else
        sql[:select] << "CONCAT_WS(' ext:', cr_phone.number, cr_phone.extension) AS phone"
        sql[:joins] << [join_on_contact_routes("cr_phone")] 
      end
      line.add_conditions!(sql, "CONCAT_WS(' ext:', cr_phone.number, cr_phone.extension)", "phone")
    end
    
    def phone_number_to_report_sql(line, sql)
      route_attr_to_report_sql(PhoneContactRoute, :cr_phone, :number, :phone_number, line, sql)
    end
    
    def phone_extension_to_report_sql(line, sql)
      route_attr_to_report_sql(PhoneContactRoute, :cr_phone, :extension, :phone_extension, line, sql)
    end
    
    def websites_to_report_sql(line, sql)
      route_attr_to_report_sql(LinkContactRoute, :cr_link, :url, :website, line, sql)
    end
    
    def product_tagged_any_to_report_sql(line, sql)
      ids = product_tagged_with(:any, line)
      sql[:joins] << join_on_products
      operator = line.excluded? ? "NOT IN" : "IN"
      sql[:conditions][0] << "#{Product.table_name}.#{Product.primary_key} #{operator} (?)"
      sql[:conditions][1] << (ids.empty? ? [0] : ids)
    end
    
    def product_tagged_all_to_report_sql(line, sql)
      ids = product_tagged_with(:all, line)
      sql[:joins] << join_on_products
      operator = line.excluded? ? "NOT IN" : "IN"
      sql[:conditions][0] << "#{Product.table_name}.#{Product.primary_key} #{operator} (?)"
      sql[:conditions][1] << (ids.empty? ? [0] : ids)
    end
    
    def product_tagged_with(type, line)
      self.account.products.find_tagged_with(type => line.value, :select => "#{Product.table_name}.#{Product.primary_key}").map(&:id)
    end

    def listing_tagged_any_to_report_sql(line, sql)
      ids = listing_tagged_with(:any, line)
      sql[:joins] << join_on_listings
      operator = line.excluded? ? "NOT IN" : "IN"
      sql[:conditions][0] << "#{Listing.table_name}.#{Listing.primary_key} #{operator} (?)"
      sql[:conditions][1] << (ids.empty? ? [0] : ids)
    end
    
    def listing_tagged_all_to_report_sql(line, sql)
      ids = listing_tagged_with(:all, line)
      sql[:joins] << join_on_listings
      operator = line.excluded? ? "NOT IN" : "IN"
      sql[:conditions][0] << "#{Listing.table_name}.#{Listing.primary_key} #{operator} (?)"
      sql[:conditions][1] << (ids.empty? ? [0] : ids)
    end
    
    def listing_tagged_with(type, line)
      self.account.listings.find_tagged_with(type => line.value, :select => "#{Listing.table_name}.#{Listing.primary_key}, #{Listing.table_name}.raw_property_data").map(&:id)
    end

    def route_attr_to_report_sql(class_object, table_name, attr_name, alias_name, line, sql)
      table_name = table_name.to_s
      attr_name = attr_name.to_s
      if line.display_only?
        sql[:select] << "(SELECT #{table_name}_#{attr_name}.#{attr_name} AS #{alias_name} FROM contact_routes #{table_name}_#{attr_name} \ 
          WHERE #{table_name}_#{attr_name}.routable_type = 'Party' AND #{table_name}_#{attr_name}.routable_id = parties.id \ 
          AND #{table_name}_#{attr_name}.type = '#{class_object.class.name}' ORDER BY position LIMIT 1) #{attr_name}"
        sql[:order] << "#{alias_name} #{line.order}" if line.order =~ /asc|desc/i
      else
        sql[:select] << "#{table_name}_#{attr_name}.#{attr_name} #{alias_name}"
        sql[:joins] << [join_on_contact_routes("#{table_name}_#{attr_name}")]
      end
      line.add_conditions!(sql, "#{table_name}_#{attr_name}.#{attr_name}", "#{alias_name}")
    end
    
    def join_on_profiles
      ["INNER JOIN profiles ON profiles.id = parties.profile_id"]
    end

    def join_on_groups
      self.join_on_memberships + ["INNER JOIN groups ON groups.id = memberships.group_id"]
    end
    
    def join_on_memberships
      ["INNER JOIN memberships ON memberships.party_id = parties.id"]
    end

    def join_on_contact_requests
      ["LEFT JOIN contact_requests ON contact_requests.party_id = parties.id"]
    end

    def join_on_phones_as_cr_phones
      ["LEFT JOIN contact_routes cr_phones ON cr_phones.routable_id = parties.id AND cr_phones.routable_type = 'Party' AND cr_phones.type = 'PhoneContactRoute'"]
    end

    def join_on_links_as_cr_links
      ["LEFT JOIN contact_routes cr_links ON cr_links.routable_id = parties.id AND cr_links.routable_type = 'Party' AND cr_links.type = 'LinkContactRoute'"]
    end

    def join_on_emails_as_cr_emails
      ["LEFT JOIN contact_routes cr_emails ON cr_emails.routable_id = parties.id AND cr_emails.routable_type = 'Party' AND cr_emails.type = 'EmailContactRoute'"]
    end

    def join_on_addresses_as_cr_addresses
      ["LEFT JOIN contact_routes cr_addresses ON cr_addresses.routable_id = parties.id AND cr_addresses.routable_type = 'Party' AND cr_addresses.type = 'AddressContactRoute'"]
    end

    def join_on_invoices
      ["INNER JOIN invoices ON invoices.invoice_to_id = parties.id"]
    end

    def join_on_invoice_lines
      [join_on_invoices, "INNER JOIN invoice_lines ON invoice_lines.invoice_id = invoices.id"]
    end

    def join_on_orders
      ["INNER JOIN orders ON orders.invoice_to_id = parties.id"]
    end

    def join_on_order_lines
      [join_on_orders, "INNER JOIN order_lines ON order_lines.order_id = orders.id"]
    end

    def join_on_products
      [join_on_order_lines, "INNER JOIN products ON products.id = order_lines.product_id"]
    end

    def join_on_product_categories
      [join_on_products, "INNER JOIN product_categories_products ON product_categories_products.product_id = products.id",
          "INNER JOIN product_categories ON product_categories_products.product_category_id = product_categories.id"]
    end

    def join_on_interests
      ["INNER JOIN interests ON interests.party_id = parties.id"]
    end

    def join_on_listings
      [join_on_interests, "INNER JOIN listings ON listings.id = interests.listing_id"]
    end   
  end

  # All parties are granted the right to edit their own accounts and parties
  # that they themselves created (are the author of).
  def total_granted_permissions
    perms = [Permission.find_or_create_by_name("edit_own_account"), Permission.find_or_create_by_name("edit_own_contacts_only")]
    raise "Could not create default permissions: #{perms.inspect}" if perms.any?(&:new_record?)

    perms = self.groups.inject(perms) {|memo, group| memo << group.total_granted_permissions}
    perms = self.roles.inject(perms) {|memo, role| memo << role.total_granted_permissions}
    perms << self.permissions
    perms.flatten.compact.uniq
  end

  # Parties are not denied any permissions by default.
  def total_denied_permissions
    perms = self.groups.inject([]) {|memo, group| memo << group.total_denied_permissions}
    perms = self.roles.inject(perms) {|memo, role| memo << role.total_denied_permissions}
    perms << self.denied_permissions
    perms.flatten.compact.uniq
  end
  
  def grant_all_permissions
    self.permissions = Permission.find(:all)
  end
  
  def add_point_in_domain(points, domain)
    current_time = Time.now.utc
    ActiveRecord::Base.transaction do
      self.update_attribute(:own_point, self.own_point + points)
      domain_point = self.domain_points.find(:first, :conditions => {:account_id => self.account_id, :domain_id => domain.id})
      if domain_point
        domain_point.update_attribute(:own_point, domain_point.own_point + points)
      else
        domain_point = self.domain_points.create!(:own_point => points, :domain_id => domain.id, :account_id => self.account_id, :party_id => self.id)
      end
      month = current_time.month
      year = current_time.year
      domain_monthly_point = self.domain_monthly_points.find(:first, :conditions => {:account_id => self.account.id, :domain_id => domain.id, :party_id => self.id, :month => month, :year => year})
      if domain_monthly_point
        domain_monthly_point.update_attribute(:own_point, domain_monthly_point.own_point + points)
      else
        domain_monthly_point = self.domain_monthly_points.create!(:own_point => points, :domain_id => domain.id, :account_id => self.account_id, :party_id => self.id, :month => month, :year => year)
      end
    end
  end
  
  def own_imap_account?
    ImapEmailAccount.count(:conditions => {:party_id => self.id, :account_id => self.account_id}) > 0 ? true : false
  end
  
  def own_imap_account
    ImapEmailAccount.first(:conditions => {:party_id => self.id, :account_id => self.account_id})
  end
  
  def own_smtp_account?
    SmtpEmailAccount.count(:conditions => {:party_id => self.id, :account_id => self.account_id}) > 0 ? true : false
  end
  
  def own_smtp_account
    SmtpEmailAccount.first(:conditions => {:party_id => self.id, :account_id => self.account_id})
  end
  
  def shared_email_account_ids
    email_account_ids = []
    t_role_ids = self.roles.all(:select => "roles.id").map(&:id)
    t_shared_email_accounts = SharedEmailAccount.all(:select => "email_account_id",
      :conditions => {:target_type => "Role", :target_id => t_role_ids}).map(&:email_account_id)
    email_account_ids += t_shared_email_accounts
    t_shared_email_accounts = SharedEmailAccount.all(:select => "email_account_id",
      :conditions => {:target_type => "Party", :target_id => self.id}).map(&:email_account_id)
    email_account_ids += t_shared_email_accounts
    email_account_ids
  end
  
  def all_imap_accounts
    email_account_ids = self.shared_email_account_ids
    email_account_ids << self.own_imap_account.id if self.own_imap_account? && self.own_imap_account.enabled?
    email_account_ids.uniq!
    return [] if email_account_ids.empty?
    ImapEmailAccount.all(:conditions => {:id => email_account_ids, :enabled => true})
  end
  
  def all_smtp_accounts
    email_account_ids = self.shared_email_account_ids
    email_account_ids << self.own_smtp_account.id if self.own_smtp_account? && self.own_smtp_account.enabled?
    email_account_ids.uniq!
    return [] if email_account_ids.empty?
    SmtpEmailAccount.all(:conditions => {:id => email_account_ids, :enabled => true})
  end
  
  def email_conversations_with(target_party, since=2.weeks.ago)
    target_email_addresses = target_party.email_addresses.all(:select => "email_address").map(&:email_address)
    email_address_prefixes = target_email_addresses.map{|e| e.split("@").first}.uniq
    emails = []
    t_emails = nil
    self.all_imap_accounts.each do |imap_account|
      begin
      
      # setup the IMAP connection and login
      imap = Net::IMAP.new(imap_account.connecting_server, imap_account.connecting_port)
      imap.login(imap_account.username, imap_account.password)
      
      # TODO need to implement a more powerful method than these two level checks
      mailboxes = []
      root_mailboxes = imap.list("", "%")
      mailboxes += root_mailboxes
      root_mailboxes.each do |root_mailbox|
        result = imap.list("", (root_mailbox.name + root_mailbox.delim + "%"))
        mailboxes += result if result
      end
      # END OF TODO
      
      # only include INBOX and SENT here      
      mailboxes = mailboxes.map(&:name)
      mailboxes.uniq!
      inbox_mailbox = nil
      sent_mailbox = nil
      mailboxes.each do |mailbox|
        case mailbox
        when /inbox/i
          inbox_mailbox = mailbox
        when /sent/i
          sent_mailbox = mailbox
        end
      end
      
      [inbox_mailbox, sent_mailbox].compact.each do |mailbox|
        external_email_ids = []
        imap.examine(mailbox)
        email_address_prefixes.each do |prefix|
          ["FROM", "CC", "TO"].each do |field|
            temp = ["SINCE", since.strftime("%d-%b-%Y"), field, prefix]
            external_email_ids += imap.uid_search(temp)
          end
        end

        next if external_email_ids.empty?
        t_emails = imap.uid_fetch(external_email_ids, ["ENVELOPE", "BODY[TEXT]", "UID"]).map{|e| {:envelope => e.attr["ENVELOPE"], :body_text => e.attr["BODY[TEXT]"], :uid => e.attr["UID"]}}
        from_string, imap_address, envelope = nil, nil, nil
        t_emails.each do |email_attr|
          # TODO needs to perform another filtering here, check for the exact email address not just using prefix
          envelope = email_attr[:envelope]
          imap_address = envelope.from.first
          from_string = imap_address.name
          from_string = imap_address.mailbox unless from_string
          
          emails << {
            :id => email_attr[:uid],
            :from => from_string,
            :subject_with_body => (envelope.subject + " - " + ActionView::Helpers::TextHelper.truncate(self.strip_tags(email_attr[:body_text]), :length => 50)),
            :date => Time.parse(envelope.date),
            :email_account_id => imap_account.id,
            :mailbox => mailbox
          }
        end
      end

      ensure
      imap.disconnect
      end
    end
    emails = emails.sort_by{|e| e[:date]}.reverse
    out = []
    emails.each do |email|
      out << {
        :id => email[:id],
        :from => email[:from],
        :subject_with_body => email[:subject_with_body],
        :date => email[:date].strftime("%b %d, %Y"),
        :email_account_id => email[:email_account_id],
        :mailbox => email[:mailbox]
      }
    end
    out
  end
  
  def purchased_products
    orders = self.account.orders.all(:conditions => "invoice_to_id = #{self.id} AND paid_in_full_at IS NOT NULL")
    products = []
    orders.each do |o|
      o.lines.each do |line|
        products << line.product
      end
    end
    products.compact.uniq
  end
  
  def convert_to_affiliate_account!(s_domain=nil)
    return false if self.confirmation_token || !self.has_email_contact_route? || self.password_hash.blank? || self.password_salt.blank?
    email_address = self.main_email.email_address
    affiliate_account = AffiliateAccount.find_by_email_address(email_address)
    return false if affiliate_account
    ActiveRecord::Base.transaction do
      affiliate_account = AffiliateAccount.new
      %w(first_name middle_name last_name honorific company_name position).each do |attr_name|
        affiliate_account.send(attr_name + "=", self.send(attr_name))
      end
      affiliate_account.email_address = email_address
      affiliate_account.source_domain = s_domain if s_domain
      affiliate_account.source_party = self
      affiliate_account.save(false)
      affiliate_account.generate_username
      affiliate_account.password_hash = self.password_hash
      affiliate_account.password_salt = self.password_salt
      affiliate_account.save!
      unless self.main_address.new_record?
        t_attrs = self.main_address.attributes
        t_attrs[:name] = "Mailing"
        affiliate_account.update_address(t_attrs)
      end
      affiliate_account
    end
  end
  
  def has_email_contact_route?
    return false if self.new_record?
    (EmailContactRoute.count(:id, :conditions => {:routable_type => "Party", :routable_id => self.id}) > 0)
  end
  
  def has_affiliate_account?
    email = self.main_email
    return false if email.new_record?
    af = AffiliateAccount.find(:first, :select => "id", :conditions => {:email_address => email.email_address})
    af ? true : false
  end
  
  def affiliate_account
    AffiliateAccount.find(:first, :conditions => {:email_address => self.main_email.email_address})
  end
  
  def affiliate_account_real_id
    AffiliateAccount.find(:first, :select => "id", :conditions => {:email_address => self.main_email.email_address})
  end
  
  def affiliate_id
    af = AffiliateAccount.find(:first, :select => "username", :conditions => {:email_address => self.main_email.email_address})
    return nil unless af
    af.username
  end
  alias_method :affiliate_username, :affiliate_id
  
  def affiliate_account_uuid
    af = AffiliateAccount.find(:first, :select => "uuid", :conditions => {:email_address => self.main_email.email_address})
    return nil unless af
    af.uuid
  end
  
  protected
  before_create :generate_random_uuid
  
  def process_affiliate_account(affiliate_account)
    ac_item = AffiliateAccountItem.new(:affiliate_account => affiliate_account, :target => self)
    ac_item.save
    true
  end

  def update_auto_permissions
    if self.customer? || self.client? then
      append_permissions(:view_own_quotes, :view_own_schedule, :edit_own_attachments, :edit_own_estimates)
    end

    append_permissions(:edit_own_account) unless self.candidate?
    append_permissions(:edit_own_schedule) if self.staff? || self.installer? || self.candidate? || self.customer?
    append_permissions(:edit_own_quotes) if self.installer?
  end

  def self.options_to_array_and_hash(options)
    if options[:conditions].kind_of?(Array) then
      conditions = [options[:conditions].first]
      values = options[:conditions][1..-1]
    else
      conditions = [options[:conditions]]
      values = {}
    end

    conditions.delete_if {|c| c.blank?}
    [conditions, values]
  end

  def set_default_order_type
    self.order_type = 'unknown' if self.order_type.blank? and self.supplier?
  end

  def strip_names
    self.company_name = (self.company_name || "").strip
    self.first_name = (self.first_name || "").strip
    self.middle_name = (self.middle_name || "").strip
    self.last_name = (self.last_name || "").strip    
  end
  
  def generate_display_name
    self.display_name = [self.company_name, self.last_name, self.first_name].reject(&:blank?).join(', ')
    return unless self.display_name.blank?
    if self.main_email then
      self.display_name = (self.main_email.email_address || "").split("@").first
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

  def email_addresses_as_text
    self.email_addresses.map(&:address)
  end

  def tags_as_text
    self.tags.map(&:name)
  end
  
  def self.new_party_from(base_party)
    new_party = Party.new
    [:links, :addresses, :phones].each do |contact_routes|
      base_party.send(contact_routes).each do |contact_route|
        new_party_contact_route = new_party.send(contact_routes).build
        logger.debug("====> i am here #{contact_route.class.content_columns.map(&:name).inspect}")
        contact_route.class.content_columns.reject {|c| c.name == "position"}.map(&:name).each do |attribute|
          new_party_contact_route.send("#{attribute}=".to_sym, contact_route.send(attribute.to_sym))
        end
      end
      base_party.send(contact_routes)
    end
    
    [:company_name].each do |attr_to_copy|
      new_party.send("#{attr_to_copy}=".to_sym, base_party.send(attr_to_copy))
    end
    
    new_party
  end
  
  def set_effective_permissions
    return if !self.new_record? && !self.update_effective_permissions
    self.generate_effective_permissions
  end
  
  def generate_effective_permissions
    effective_permissions = [Permission.find_by_name("edit_own_account"), Permission.find_by_name("edit_own_contacts_only")].compact
    denied_permissions = []
    self.groups.each do |group|
      effective_permissions += group.total_granted_permissions
      denied_permissions += group.total_denied_permissions
    end
    self.roles.each do |role|
      effective_permissions += role.total_granted_permissions
      denied_permissions += role.total_denied_permissions
    end
    effective_permissions += self.permissions.reload
    denied_permissions += self.denied_permissions.reload
    
    effective_permissions = effective_permissions.map(&:id).uniq
    denied_permissions =  denied_permissions.map(&:id).uniq
    
    effective_permissions = effective_permissions - denied_permissions
    
    ActiveRecord::Base.connection().execute(%Q~
      DELETE FROM effective_permissions WHERE party_id = #{self.id}
    ~)
    
    return if effective_permissions.blank?
    values_array = effective_permissions.map{|e| [self.id, e]}
    
    values_array = values_array.inspect[1..-2]
    values_array = values_array.gsub("[","(").gsub("]", ")")
    
    ActiveRecord::Base.connection().execute(%Q~
      INSERT INTO effective_permissions (`party_id`,`permission_id`) VALUES #{values_array}
    ~)    
  end
  
  def set_blog_posts_author_to_account_owner
    self.blog_posts.each do |blog_post|
      blog_post.author_id = self.account.owner.id
      blog_post.save
    end
  end
end
