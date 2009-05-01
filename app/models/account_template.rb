#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class AccountTemplate < ActiveRecord::Base
  include XlSuite::PicturesHelper
  has_many :audio_files, :source => :asset, :through => :views, :order => "views.position", :conditions => Asset::AUDIO_FILES_CONDITION
  has_many :flash_files, :source => :asset, :through => :views, :order => "views.position", :conditions => Asset::FLASH_FILES_CONDITION
  has_many :shockwave_files, :source => :asset, :through => :views, :order => "views.position", :conditions => Asset::SHOCKWAVE_FILES_CONDITION
  has_many :multimedia, :source => :asset, :through => :views, :order => "views.position", :conditions => ["views.classification=?", "multimedia"]
  has_many :other_files, :source => :asset, :through => :views, :order => "views.position", :conditions => ["views.classification=?", "other_files"]

  validates_presence_of :name, :trunk_account_id
  validates_uniqueness_of :name, :trunk_account_id, :scope => [:account_id]
  
  belongs_to :account
  belongs_to :trunk_account, :class_name => "Account"
  belongs_to :stable_account, :class_name => "Account"
  
  belongs_to :approved_by, :class_name => "Party"
  belongs_to :unapproved_by, :class_name => "Party"
  
  has_many :installed_account_templates, :dependent => :destroy
  
  after_destroy :destroy_template_accounts
  
  acts_as_taggable
  acts_as_reportable
  
  acts_as_money :setup_fee, :subscription_markup_fee
  acts_as_period :period, :allow_nil => true
  
  serialize :previous_stables
  
  before_save :set_account_to_xlsuite
  
  attr_accessor :main_theme_id, :industry_id, :updating_category
  after_save :update_category
  
  AVAILABLE_MODULES = %w(blogs directories forums product_catalog profiles real_estate_listings rss_feeds testimonials workflows cms).freeze
  
  def push_trunk_to_stable!(options={})
    ActiveRecord::Base.transaction do
      options = options.dup.symbolize_keys
      options.reverse_merge!({
        :pages => false, :snippets => false, :layouts => false,
        :groups => false,
        :assets => false, 
        :products => false, 
        :contacts => false,
        :blogs => false,
        :workflows => false,
        :feeds => false})
      domain_patterns = options.delete(:domain_patterns) || "**"
      options.merge!(:domain_patterns => domain_patterns)
      new_account = Account.new
      new_account.disable_copy_account_configurations = true
      new_account.expires_at = 100.years.from_now
      new_account.save!
      options.merge!(:target_account_id => new_account.id, :overwrite => true)
      copy_futures = []
      if options[:layouts]
        copy_futures << MethodCallbackFuture.create!(:account => self.trunk_account, :model => self.trunk_account, :params => options, :method => :copy_all_layouts_to!)
        object_pushed = true
      end
      if options[:snippets]
        copy_futures << MethodCallbackFuture.create!(:account => self.trunk_account, :model => self.trunk_account, :params => options, :method => :copy_all_snippets_to!)
        object_pushed = true
      end
      if options[:pages]
        copy_futures << MethodCallbackFuture.create!(:account => self.trunk_account, :model => self.trunk_account, :params => options, :method => :copy_all_pages_to!)
        object_pushed = true
      end
      if options[:groups]
        copy_futures << MethodCallbackFuture.create!(:account => self.trunk_account, :model => self.trunk_account, :params => options, :method => :copy_all_groups_and_roles_to!)
        object_pushed = true
      end
      if options[:assets]
        copy_futures << MethodCallbackFuture.create!(:account => self.trunk_account, :model => self.trunk_account, :params => options, :method => :copy_all_assets_to!)
        object_pushed = true
      end
      copy_futures << MethodCallbackFuture.create!(:account => self.trunk_account, :model => self.trunk_account, :params => options, :method => :copy_all_configurations_to!)
      if options[:products]
        copy_futures << MethodCallbackFuture.create!(:account => self.trunk_account, :model => self.trunk_account, :params => options, :method => :copy_all_products_and_product_categories_to!)
        object_pushed = true
      end
      if options[:contacts]
        copy_futures << MethodCallbackFuture.create!(:account => self.trunk_account, :model => self.trunk_account, :params => options, :method => :copy_all_contacts_to!)
        object_pushed = true
      end
      if options[:blogs]
        copy_futures << MethodCallbackFuture.create!(:account => self.trunk_account, :model => self.trunk_account, :params => options, :method => :copy_all_blogs_and_blog_posts_to!)
        object_pushed = true
      end
      if options[:workflows]
        copy_futures << MethodCallbackFuture.create!(:account => self.trunk_account, :model => self.trunk_account, :params => options, :method => :copy_all_workflows_to!)
        object_pushed = true
      end
      if options[:feeds]
        copy_futures << MethodCallbackFuture.create!(:account => self.trunk_account, :model => self.trunk_account, :params => options, :method => :copy_all_feeds_to!)
        object_pushed = true
      end
      if options[:email_templates]
        copy_futures << MethodCallbackFuture.create!(:account => self.trunk_account, :model => self.trunk_account, :params => options, :method => :copy_all_email_templates_to!)
        object_pushed = true
      end
      if options[:links]
        copy_futures << MethodCallbackFuture.create!(:account => self.trunk_account, :model => self.trunk_account, :params => options, :method => :copy_all_links_to!)
        object_pushed = true
      end
      return false unless object_pushed
      callbacks_future = MethodCallbackFuture.create!(:models => [self], :account => new_account, :method => :callbacks_after_template_push, :repeat_until_true => true, 
            :params => {:future_ids => copy_futures.map(&:id), :target_account_id => new_account.id}, :priority => 75)
      self.push_current_stable_to_previous
      self.stable_account_id = new_account.id
      self.save!
    end
  end
  
  def callbacks_after_template_push(args)
    future_ids = args[:future_ids]
    status_hash = Future.get_status_of(future_ids)
    if status_hash['isCompleted']
      MethodCallbackFuture.create(:priority => 75, :models => [self.trunk_account], :account => self.trunk_account, :method => :attach_product_accessible_items_to!, :params => {:target_account_id => args[:target_account_id], :overwrite => true})
      AdminMailer.deliver_template_pushed_email(self.trunk_account, self)
      return true
    end
    return false
  end
  
  def rollback_stable!
    return false if self.previous_stables.blank? || self.previous_stables.size < 1
    AccountTemplate.transaction do
      MethodCallbackFuture.create!(:account => Account.find(1), :model => self.stable_account, :method => "destroy")
      self.stable_account_id = self.previous_stables.pop.to_i
      self.save!
    end
    true
  end
  
  def main_theme
    categories = Categorizable.all(:conditions => {:subject_type => "AccountTemplate", :subject_id => self.id})
    c_id = (categories.map(&:category_id) & self.class.main_theme_categories.map(&:id)).first
    return nil unless c_id
    Category.find(c_id)
  end
  
  def industry
    categories = Categorizable.all(:conditions => {:subject_type => "AccountTemplate", :subject_id => self.id})
    c_id = (categories.map(&:category_id) & self.class.industry_categories.map(&:id)).first
    return nil unless c_id
    Category.find(c_id)
  end
  
  def selected_modules
    self.attributes.select{|key, value| self.class.functionality_column_names.include?(key)}.reject {|e| e[1] == false}.map{|e| e[0].sub(/^f_/i, "")} 
  end
  
  def minimum_subscription_fee
    AccountModule.count_minimum_subscription_fee(self.selected_modules)
  end
  
  def self.functionality_column_names
    self.column_names.select {|e| e =~ /^f_/i}
  end
  
  def self.main_theme_categories
    master_acct = Account.find_by_master(true)
    return [] unless master_acct
    c = master_acct.categories.find_by_label("main_theme")
    return [] unless c
    c.children
  end
  
  def self.industry_categories
    master_acct = Account.find_by_master(true)
    return [] unless master_acct
    c = master_acct.categories.find_by_label("industry")
    return [] unless c
    c.children
  end
  
  def subscription_fee
    self.minimum_subscription_fee + self.subscription_markup_fee
  end
  
  def main_image_url
    main_image = self.images.first
    return "" unless main_image && self.trunk_account
    "http://" + self.trunk_account.domains.first.name + "/assets/download/" + main_image.filename
  end
  
  def designer
    self.trunk_account ? self.trunk_account.owner : "Unavailable"
  end
  
  def installed_count
    self.installed_account_templates.count
  end
  
  def features_list
    return "None" if self.selected_modules.empty?
    self.selected_modules.map(&:humanize).join(", ")
  end
  
  def approve!(user)
    self.approved_at = Time.now.utc
    self.approved_by = user
    self.save!
  end
  
  def unapprove!(user)
    self.approved_at = nil
    self.unapproved_at = Time.now.utc
    self.unapproved_by = user
    self.save!
  end
  
  def approved?
    !self.approved_at.nil?
  end
  
  protected
  
  def update_category
    return unless self.updating_category
    main_theme_category_ids = self.class.main_theme_categories.map(&:id)
    industry_category_ids = self.class.industry_categories.map(&:id)
    Categorizable.delete_all({:subject_type => "AccountTemplate", :subject_id => self.id, :category_id => main_theme_category_ids})
    Categorizable.delete_all({:subject_type => "AccountTemplate", :subject_id => self.id, :category_id => industry_category_ids})
    if !self.main_theme_id.blank?
      Categorizable.create!(:subject => self, :category => Category.find(self.main_theme_id))
    end
    if !self.industry_id.blank?
      Categorizable.create!(:subject => self, :category => Category.find(self.industry_id))
    end
  end
  
  def push_current_stable_to_previous
    return if self.stable_account_id.blank?
    self.previous_stables = [] if self.previous_stables.nil? || !self.previous_stables.kind_of?(Array)
    self.previous_stables.push(self.stable_account_id)
    if self.previous_stables.size > 5
      MethodCallbackFuture.create!(:account => Account.find(1), :model => Account.find(self.previous_stables.shift), :method => "destroy")
    end
    true
  end
  
  def set_account_to_xlsuite
    self.account_id = 1
  end
  
  def destroy_template_accounts
    result = []
    result << self.stable_account if self.stable_account
    if self.previous_stables && !self.previous_stables.empty?
      self.previous_stables.each do |acct_id|
        result << Account.find(acct_id.to_i)
      end
    end
    unless result.empty?
      MethodCallbackFuture.create!(:system => true, :models => result, :method => "destroy")
    end
    true
  end
end
