#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Account < ActiveRecord::Base
  include XlSuite::AffiliateAccountHelper
  
  acts_as_fulltext %w(account_owner_display_name_as_text), %w(domain_names_as_text account_owner_email_as_text due_date_as_text cost_as_text)
  acts_as_tree :foreign_key => :signup_account_id

  belongs_to :owner, :class_name => 'Party', :foreign_key => 'party_id'
  has_many :domains, :order => 'id', :dependent => :destroy
  has_many :domain_subscriptions, :order => 'id', :dependent => :destroy
  
  belongs_to :order

  validates_uniqueness_of :party_id, :allow_nil => true
  validates_presence_of :expires_at

  before_destroy :send_reminder_email_if_not_activated 
  before_destroy :send_expired_account_deleted_email 

  has_many :account_payments, :class_name => "Payment", :as => :payable
  
  has_many :listings, :conditions => "type IS NULL", :dependent => :destroy
  
  %w( configurations contact_requests feeds parties api_keys tags testimonials
      carts
      estimates
      orders
      invoices
      payments payment_transitions payables
      timelines
      assets profiles profile_add_requests profile_claim_requests profile_requests
      mappers imports fulltext_rows
      links link_categories
      products product_categories entities sale_events suppliers
      sale_event_items all_products_sale_event_items product_sale_event_items product_category_sale_event_items
      books providers
      groups roles
      templates searches
      contact_routes email_contact_routes address_contact_routes phone_contact_routes link_contact_routes
      emails recipients email_accounts mass_recipients
      forums forum_categories forum_posts forum_topics 
      destinations payment_terms
      blogs blog_posts comments
      folders referrals reports filters email_labels
      polygons
      rents 
      flaggings
      assignees steps tasks workflows
      installed_account_templates account_modules account_module_subscriptions subscriptions
      categories affiliates party_domain_points cached_pages action_handlers).each do |table|
    table.singularize.classify.constantize # Ensure the associated model exists
    has_many table.to_sym, :dependent => :destroy
  end

  %w( pages layouts snippets redirects futures ).each do |table|
    table.singularize.classify.constantize # Ensure the associated model exists
    has_many table.to_sym, :dependent => :delete_all
  end
  
  has_one :account_template_as_trunk, :class_name => "AccountTemplate", :foreign_key => :trunk_account_id

  def mass_emails
    self.emails.find(:all, :conditions => {:mass_mail => true})
  end

  serialize :options
  attr_accessible :owner, :confirmation_url, :registering, :title, :payment_plan_id,
      :confirmation_token_expires_at, :confirmation_token, :template_name, :selected_modules, :account_template_id,
      :suite_id, :referral_domain

  attr_accessor :registering, :confirmation_url, :disable_copy_account_configurations
  before_save :set_confirmation_token
  after_save :send_confirmation_email
  after_create {|account| CopyAccountConfigurationsFuture.create!(:account => account, :owner => account.owner) \
                            unless account.disable_copy_account_configurations}

  # During signup, we ask the user for a template and modules to use
  attr_accessor :template_name, :selected_modules, :account_template_id
  
  # Needed for embed suites feature, embed install form supposedly passes in both suite_id parameters
  attr_accessor :suite_id

  def selected_modules
    @selected_modules ||= []
  end

  def options
    @options_proxy ||= AccountOptionsProxy.new(self)
  end

  AccountModule::AVAILABLE_MODULES.each do |option_name|
    class_eval <<-EOF
      def #{option_name}_option=(value)
        real_options[#{option_name.inspect}.to_sym] = true == value || '1' == value
      end

      def #{option_name}_option
        real_options[#{option_name.inspect}.to_sym]
      end
    EOF
  end

  def real_options
    @real_options ||= returning(read_attribute(:options) || Hash.new) do |opts|
      write_attribute(:options, opts)
    end
  end
  
  def generate_order_on!(master_account, date=Date.today)
    return if self.cost.zero?
    returning master_account.orders.create!(:customer => self.owner, :date => date, :referencable => self) do |order|
      order.fst_active = (self.owner.main_address.country == master_account.owner.main_address.country)
      order.pst_active = (order.fst_active && self.owner.main_address.state == master_account.owner.main_address.state)
      order.lines << OrderLine.new(:quantity => 1, :retail_price => self.cost,
                                   :description => "#{master_account.domain_name} hosting for domain #{self.domains(true).first.name}")
      order.save!
      order.update_attribute(:account, master_account)
      self.order = order
      self.save!
    end
  end
  
  OWNER_ADDRESS_ATTRIBUTE = %w(state country)
  OWNER_ADDRESS_ATTRIBUTE.each do |attr_name|
    class_eval <<-"end_eval"
      def #{attr_name}
        return nil unless self.owner && self.owner.main_address && !self.owner.main_address.#{attr_name}.blank?
        self.owner.main_address.#{attr_name}
      end
    end_eval
  end

  def expired?
    self.expires_at < Time.now
  end

  def nearly_expired?
    (Time.now .. 7.days.from_now).include?(self.expires_at)
  end

  def cost
    self.base_cost + self.options_cost
  end

  def formatted_options
    ""
  end

  def title
    read_attribute(:title) || default_title
  end

  def name
    title
  end

  # Return the canonical domain name of this account.
  def domain_name
    candidates = self.sorted_domains.map(&:name).reject(&:blank?)
    candidates.reject! {|name| name =~ /^(?:\d{1,3}[.]){3}\d{1,3}$/} # Reject IP addresses

    candidates = candidates.sort_by(&:length).reverse # Prefer longer names (www vs non-www)
    best_candidates = candidates.reject {|name| name =~ /[.]xlsuite[.]\w+$/} # Reject XLsuite subdomains
    best_candidates.first || candidates.first 
  end

  def canonical_domain
    self.domains.find_by_name(self.domain_name)
  end

  def default_title
    (self.domains.first || Domain.new(:name => "unknown")).name
  end

  def to_s
    self.title
  end

  def sorted_domains
    self.domains.sort_by {|domain| domain.name.split(".").reverse}
  end

  def get_config(name)
    Configuration.get(name, self)
  end

  def set_config(name, value)
    Configuration.set(name, value, self)
  end

  def registering?
    self.registering || false
  end

  def activate!
    @activation_attempt = true
    self.confirmation_token = nil
    self.confirmation_token_expires_at = nil
    self.save!
  end
  
  def activated?
    self.confirmation_token.nil? && self.confirmation_token_expires_at.nil?
  end
  
  # Looking for templates
  # This involves looking at one level higher than our current domain to see if there are any "template.**"
  # And up again, until we hit the root.
  def available_templates
    available_names_by_role(Domain::TemplateRole)
  end
  
  def available_house_templates
    available_names_by_role(Domain::HouseTemplateRole)
  end

  def default_template
    available_templates.detect {|t| t.price.zero?}.if_not_nil(&:name)
  end

  def available_modules
    available_names_by_role(Domain::ModuleRole)
  end

  def copy_template_and_modules!
    logger.debug {"==> Copying template and modules over"}
    logger.debug {"==> Template Name: #{self.template_name.inspect}"}
    logger.debug {"==> Module Names: #{self.selected_modules.inspect}"}
    self.copy_template!
    self.copy_modules!
  end

  def copy_template!
    return if self.template_name.blank?

    domain = Domain.find_by_name(self.template_name)
    
    MethodCallbackFuture.create!(:models => [self], :account =>  self, :method => :copy_cms_components_from!, :params => {:source_domain_id => domain.id, :overwrite => true})
    MethodCallbackFuture.create!(:models => [self], :account =>  self, :method => :copy_groups_and_roles_from!, :params => {:source_domain_id => domain.id, :overwrite => true})
    MethodCallbackFuture.create!(:models => [self], :account =>  self, :method => :copy_assets_from!, :params => {:source_domain_id => domain.id, :overwrite => true})
    MethodCallbackFuture.create!(:models => [self], :account =>  self, :method => :copy_feeds_from!, :params => {:source_domain_id => domain.id, :overwrite => true})
    MethodCallbackFuture.create!(:models => [self], :account =>  self, :method => :copy_products_and_product_categories_from!, :params => {:source_domain_id => domain.id, :overwrite => true})
    MethodCallbackFuture.create!(:models => [self], :account =>  self, :method => :copy_configurations_from!, :params => {:source_domain_id => domain.id, :overwrite => true})
    MethodCallbackFuture.create!(:models => [self], :account =>  self, :method => :copy_contacts_from!, :params => {:source_domain_id => domain.id, :overwrite => true})
    MethodCallbackFuture.create!(:models => [self], :account =>  self, :method => :copy_blogs_and_blog_posts_from!, :params => {:source_domain_id => domain.id, :overwrite => true})
    MethodCallbackFuture.create!(:models => [self], :account =>  self, :method => :copy_workflows_from!, :params => {:source_domain_id => domain.id, :create_dependencies => true})
  end
  
  def install_from_account_template!(account_template_id)
    copy_futures = []
    ActiveRecord::Base.transaction do
      account_template = AccountTemplate.find(account_template_id.to_i)
      stable_account = account_template.stable_account
      
      copy_futures = [MethodCallbackFuture.create!(:priority => 75, :models => [stable_account], :account => self, :method => :copy_all_cms_components_to!, :params => {:target_account_id => self.id, :overwrite => true, :modified => false}),
        MethodCallbackFuture.create!(:priority => 75, :models => [stable_account], :account => self, :method => :copy_all_groups_and_roles_to!, :params => {:target_account_id => self.id, :overwrite => true}),
        MethodCallbackFuture.create!(:priority => 75, :models => [stable_account], :account => self, :method => :copy_all_assets_to!, :params => {:target_account_id => self.id, :overwrite => true}),
        MethodCallbackFuture.create!(:priority => 75, :models => [stable_account], :account => self, :method => :copy_all_configurations_to!, :params => {:target_account_id => self.id, :overwrite => true}),
        MethodCallbackFuture.create!(:priority => 75, :models => [stable_account], :account => self, :method => :copy_all_products_and_product_categories_to!, :params => {:target_account_id => self.id, :overwrite => true}),
        MethodCallbackFuture.create!(:priority => 75, :models => [stable_account], :account => self, :method => :copy_all_contacts_to!, :params => {:target_account_id => self.id, :overwrite => true}),
        MethodCallbackFuture.create!(:priority => 75, :models => [stable_account], :account => self, :method => :copy_all_blogs_and_blog_posts_to!, :params => {:target_account_id => self.id, :overwrite => true}),
        MethodCallbackFuture.create!(:priority => 75, :models => [stable_account], :account => self, :method => :copy_all_workflows_to!, :params => {:target_account_id => self.id, :overwrite => true}),
        MethodCallbackFuture.create!(:priority => 75, :models => [stable_account], :account => self, :method => :copy_all_feeds_to!, :params => {:target_account_id => self.id, :overwrite => true}),
        MethodCallbackFuture.create!(:priority => 75, :models => [stable_account], :account => self, :method => :copy_all_email_templates_to!, :params => {:target_account_id => self.id, :overwrite => true}),
        MethodCallbackFuture.create!(:priority => 75, :models => [stable_account], :account => self, :method => :copy_all_links_to!, :params => {:target_account_id => self.id, :overwrite => true})
      ]
      callbacks_future = MethodCallbackFuture.create!(:models => [self], :account => self, :method => :callbacks_after_account_install, :repeat_until_true => true, 
            :params => {:future_ids => copy_futures.map(&:id), :type => "account_install", :stable_account => stable_account}, :priority => 75)
    end
    return copy_futures.map(&:id)
  end

  def callbacks_after_account_install(args)
    future_ids = args[:future_ids]
    status_hash = Future.get_status_of(future_ids)
    if status_hash['isCompleted']
      if args[:type] =~ /account_install/i
        MethodCallbackFuture.create(:priority => 75, :models => [args[:stable_account]], :account => self, :method => :attach_product_accessible_items_to!, :params => {:target_account_id => self.id, :overwrite => true})
        AdminMailer.deliver_account_installed_email(self)
      end
      return true
    end
    return false
  end
  
  def attach_product_accessible_items_to!(args)
    target_acct = Account.find(args[:target_account_id])
    target_acct.products.each do |target_product|
      src_product = self.products.find_by_name(target_product.name)
      next unless src_product
      src_product.accessible_items.each do |accessible|
        target_item = nil
        case accessible.item_type
          when /(blog|group)/i
            target_item = target_acct.send(accessible.item_type.tableize).find_by_label(accessible.item.label)
          when /asset/i
            target_item = target_acct.assets.find_by_uuid(accessible.item.uuid)
        end
        next unless target_item
        product_item = ProductItem.new(:item => target_item, :product => target_product)
        product_item.save
      end
    end
  end

  def copy_cms_components_from!(options)
    self.copy_layouts_from!(options)
    self.copy_pages_from!(options)
    self.copy_snippets_from!(options)
  end
  
  def copy_all_cms_components_to!(options)
    self.copy_all_layouts_to!(options)
    self.copy_all_pages_to!(options)
    self.copy_all_snippets_to!(options)
  end

  def copy_groups_and_roles_from!(options)
    self.copy_groups_from!(options)
    self.copy_roles_from!(options)
  end
  
  def copy_all_groups_and_roles_to!(options)
    self.copy_all_groups_to!(options)
    self.copy_all_roles_to!(options)
  end

  def copy_modules!
    return if self.selected_modules.blank?

    self.selected_modules.each do |module_name|
      source_domain = Domain.find_by_name(module_name)
      MethodCallbackFuture.create!(:models => [self], :account =>  self, :method => :copy_cms_components_from!, :params => {:source_domain_id => source_domain.id, :overwrite => true})
      MethodCallbackFuture.create!(:models => [self], :account =>  self, :method => :copy_feeds_from!, :params => {:source_domain_id => source_domain.id, :overwrite => true})
    end
  end

  def copy_layouts_from!(options)
    domain = Domain.find(options[:source_domain_id])
    logger.debug {"==> Copying layouts from #{domain.name}"}
    domain.account.layouts.select {|layout| layout.available_on?(domain)}.each do |layout|
      self.layouts.create!(layout.attributes_for_copy_to(self))
    end
  end
  
  def copy_all_layouts_to!(options)
    logger.debug("==> Copying all layouts to target account")
    target_acct = Account.find(options[:target_account_id])
    self.layouts.each do |layout|
      t_layout = target_acct.layouts.find_by_uuid(layout.uuid)
      if t_layout
        next if t_layout.no_update?
        next if options[:exclude_layouts] && options[:exclude_layouts].include?(t_layout.id)
        t_layout.attributes = layout.attributes_for_copy_to(target_acct, options)
        t_layout.save!
      else
        t_layout = target_acct.layouts.create!(layout.attributes_for_copy_to(target_acct, options))
      end
    end
  end

  def copy_pages_from!(options)
    domain = Domain.find(options[:source_domain_id])
    logger.debug {"==> Copying pages from #{domain.name}"}
    Page.disable_domain_routing_update do
      domain.account.pages.find(:all, :conditions => {:type => "Page"}).select {|page| page.available_on?(domain)}.each do |page|
        self.pages.create!(page.attributes_for_copy_to(self))
      end
      logger.debug {"==> Copying redirects from #{domain.name}"}
      domain.account.redirects.select {|r| r.available_on?(domain)}.each do |redirect|
        self.redirects.create!(redirect.attributes_for_copy_to(self))
      end
    end
    domain.rebuild_routes!
  end
  
  def copy_all_pages_to!(options)
    logger.debug {"==> Copying pages to target account"}
    target_acct = Account.find(options[:target_account_id])
    Page.disable_domain_routing_update do
      self.pages.find(:all, :conditions => {:type => "Page"}).each do |page|
        t_page = target_acct.pages.find_or_initialize_by_uuid(page.uuid)
        if t_page.new_record?
          t_page.attributes = page.attributes_for_copy_to(target_acct, options) 
        else
          next if t_page.no_update?
          next if options[:exclude_pages].kind_of?(Enumerable) && options[:exclude_pages].include?(t_page.id)
          copy_attrs = page.attributes_for_copy_to(target_acct, options)
          copy_attrs.stringify_keys!
          copy_attrs.delete("meta_description") unless t_page.meta_description.blank?
          copy_attrs.delete("meta_keywords") unless t_page.meta_keywords.blank?
          t_page.attributes = copy_attrs
        end
        t_page.save!
      end
      logger.debug {"==> Copying redirects to target account"}
      self.redirects.each do |redirect|
        t_redirect = target_acct.redirects.find_or_initialize_by_uuid(redirect.uuid)
        next if t_redirect.no_update?
        t_redirect.attributes = redirect.attributes_for_copy_to(target_acct, options) if t_redirect.new_record? || options[:overwrite]
        t_redirect.save!
      end
    end
    target_acct.domains.map(&:rebuild_routes!)
  end

  def copy_snippets_from!(options)
    domain = Domain.find(options[:source_domain_id])
    logger.debug {"==> Copying snippets from #{domain.name}"}
    domain.account.snippets.select {|snippet| snippet.available_on?(domain)}.each do |snippet|
      s = self.snippets.build(snippet.attributes_for_copy_to(self))
      s.ignore_warnings = true
      s.save!
    end
  end

  def copy_all_snippets_to!(options)
    logger.debug {"==> Copying snippets to target account"}
    target_acct = Account.find(options[:target_account_id])
    self.snippets.each do |snippet|
      t_snippet = target_acct.snippets.find_by_uuid(snippet.uuid)
      if t_snippet
        next if t_snippet.no_update?
        next if options[:exclude_snippets].kind_of?(Enumerable) && options[:exclude_snippets].include?(t_snippet.id)
        t_snippet.attributes = snippet.attributes_for_copy_to(target_acct, options)
        t_snippet.ignore_warnings = true
        t_snippet.save!
      else
        t_snippet = target_acct.snippets.build(snippet.attributes_for_copy_to(target_acct, options))
        t_snippet.ignore_warnings = true
        t_snippet.save!
      end
    end
  end
  
  def copy_assets_from!(options)
    domain = Domain.find(options[:source_domain_id])
    logger.debug {"==> Copying assets and folders from #{domain.name}"}
    domain.account.assets.find(:all, :conditions => "parent_id IS NULL AND folder_id IS NULL").each do |asset|
      self.assets.create!(asset.attributes_for_copy_to(self))
    end
    #find all root folders
    domain.account.folders.find(:all, :conditions => "parent_id IS NULL").each do |root_folder|
      new_folder = self.folders.create!(root_folder.attributes_for_copy_to(self))
      new_folder.copy_assets_and_subfolders_from_folder!(root_folder)
    end
  end
  
  def copy_all_assets_to!(options)
    target_acct = Account.find(options[:target_account_id])

    logger.debug("==> Copying folders to target account")  
    # copy all folders
    self.folders.all.each do |folder|
      t_folder = target_acct.folders.find_by_uuid(folder.uuid)
      if t_folder
        t_folder.attributes = folder.attributes_for_copy_to(target_acct) if options[:overwrite]
      else
        t_folder = target_acct.folders.build(folder.attributes_for_copy_to(target_acct))
      end
      t_folder.save(false)
    end
    
    if options[:overwrite]
      # update parent id of all folders
      self.folders.all(:conditions => "parent_id IS NOT NULL").each do |folder|
        t_folder = target_acct.folders.find_by_uuid(folder.uuid)
        t_folder.par_id = target_acct.folders.find_by_uuid(folder.parent.uuid).id
        t_folder.save!
      end
    end
    
    logger.debug("==> Copying assets to target account")
    logger.debug("==> Copying root assets")
    # copy all root assets
    self.assets.find(:all, :conditions => "parent_id IS NULL AND folder_id IS NULL").each do |asset|
      t_asset = target_acct.assets.find_by_uuid(asset.uuid)
      begin
        if t_asset
          t_asset.attributes = asset.attributes_for_copy_to(target_acct) if options[:overwrite]
          t_asset.save!
        else
          t_asset = target_acct.assets.create!(asset.attributes_for_copy_to(target_acct))
        end
      rescue
        ExceptionNotifier.deliver_exception_caught($!, nil, :current_user => self.owner, :account => self, :request => nil)
        next
      end
    end
    
    logger.debug("==> Copying folders assets")
    # copy all folders assets
    self.assets.find(:all, :conditions => "parent_id IS NULL AND folder_id IS NOT NULL").each do |asset|
      t_asset = target_acct.assets.find_by_uuid(asset.uuid)
      begin
        if t_asset
          if options[:overwrite]
            t_asset.attributes = asset.attributes_for_copy_to(target_acct)
            t_asset.folder_id = target_acct.folders.find_by_uuid(asset.folder.uuid).id
          end
          t_asset.save!
        else
          folder_id = target_acct.folders.find_by_uuid(asset.folder.uuid).id
          t_asset = target_acct.assets.create!(asset.attributes_for_copy_to(target_acct).merge(:folder_id => folder_id))
        end
      rescue
        ExceptionNotifier.deliver_exception_caught($!, nil, :current_user => self.owner, :account => self, :request => nil)
        next
      end
    end
  end
  
  def copy_configurations_from!(options)
    domain = Domain.find(options[:source_domain_id])
    logger.debug {"==> Copying configurations from #{domain.name}"}
    Configuration.delete_all("account_id = #{self.id}")
    domain.account.configurations.each do |configuration|
      new_config = configuration.class.create!(configuration.attributes_for_copy_to(self))
      if new_config.name =~ /^(paypal_business|notify_order_email)$/
        new_config.set_value!(self.owner.main_email.email_address)
      else
        new_config.set_value!(configuration.value)
      end
    end
  end
  
  def copy_all_configurations_to!(options)
    logger.debug("==> Copying configurations to target account")
    target_acct = Account.find(options[:target_account_id])
    self.configurations.each do |configuration|
      t_config = target_acct.configurations.find_by_uuid(configuration.uuid)
      if t_config
        if t_config.name =~ /^(paypal_business|notify_order_email)$/
          t_config.set_value!(target_acct.owner ? target_acct.owner.main_email.email_address : "")
        else
          t_config.set_value!(configuration.value)
        end if options[:overwrite]
      else
        t_config = configuration.class.new(configuration.attributes_for_copy_to(target_acct))
        t_config.uuid = configuration.uuid
        t_config.save!
        if t_config.name =~ /^(paypal_business|notify_order_email)$/
          t_config.set_value!(target_acct.owner ? target_acct.owner.main_email.email_address : "")
        else
          t_config.set_value!(configuration.value)
        end
      end
    end
  end
  
  def copy_products_and_product_categories_from!(options)
    domain = Domain.find(options[:source_domain_id])
    logger.debug {"==> Copying products and product categories from #{domain.name}"}
    #first copy all products who do not belong to any product categories
    domain.account.products.find(:all).select{|p|p.categories.blank?}.each do |product|
      next if self.products.find_by_name(product.name)
      new_product = self.products.create!(product.attributes_for_copy_to(self))
      new_product.copy_assets_from!(product)
    end
    domain.account.product_categories.find(:all, :conditions => "parent_id IS NULL").each do |cat|
      new_category =  self.product_categories.find_by_name(cat.name)
      new_category ||= self.product_categories.create!(cat.attributes_for_copy_to(self))
      new_category.copy_products_and_subcategories_from_product_category!(cat)
    end
  end
  
  def copy_all_products_and_product_categories_to!(options)
    logger.debug {"==> Copying products and product categories to target account"}
    #first copy all products who do not belong to any product categories
    target_acct = Account.find(options[:target_account_id])
    self.products.find(:all, :conditions => {:owner_id => nil}).select{|p|p.categories.blank?}.each do |product|
      next if target_acct.products.find_by_name(product.name)
      new_product = target_acct.products.create!(product.attributes_for_copy_to(target_acct))
      new_product.copy_assets_from!(product)
    end
    self.product_categories.find(:all, :conditions => "parent_id IS NULL").each do |cat|
      new_category =  target_acct.product_categories.find_by_name(cat.name)
      new_category ||= target_acct.product_categories.create!(cat.attributes_for_copy_to(target_acct))
      new_category.copy_products_and_subcategories_from_product_category!(cat)
    end
  end
  
  def copy_groups_from!(options)
    domain = Domain.find(options[:source_domain_id])
    domain.account.groups.find(:all, :conditions => "parent_id IS NULL").each do |group|
      new_group = self.groups.find_by_label(group.label)
      new_group ||= self.groups.create!(group.attributes_for_copy_to(self))
      new_group.copy_child_groups_from!(group)
    end
  end
  
  def copy_all_groups_to!(options)
    logger.debug("==> Copying groups to target account")
    target_acct = Account.find(options[:target_account_id])
    self.groups.find(:all, :conditions => "parent_id IS NULL").each do |group|
      new_group = target_acct.groups.find_by_label(group.label)
      new_group ||= target_acct.groups.create!(group.attributes_for_copy_to(target_acct))
      new_group.copy_child_groups_from!(group)
    end
  end
  
  #Roles should not be added to groups or parties during template installation 
  #because then the groups/parties will have the permissions defined in the role
  def copy_roles_from!(options)
    domain = Domain.find(options[:source_domain_id])
    domain.account.roles.find(:all, :conditions => "parent_id IS NULL").each do |role|
      new_role = self.roles.find_by_name(role.name)
      new_role ||= self.roles.create!(role.attributes_for_copy_to(self))
      new_role.copy_permissions_and_child_roles_from!(role)
    end
  end
  
  def copy_all_roles_to!(options)
    logger.debug("==> Copying roles to target account")
    target_acct = Account.find(options[:target_account_id])
    self.roles.find(:all, :conditions => "parent_id IS NULL").each do |role|
      new_role = target_acct.roles.find_by_name(role.name)
      new_role ||= target_acct.roles.create!(role.attributes_for_copy_to(target_acct))
      new_role.copy_permissions_and_child_roles_from!(role)
    end
  end
  
  def copy_contacts_from!(options)
    domain = Domain.find(options[:source_domain_id])
    logger.debug("==> Copying contacts from #{domain.name}")
    domain.account.parties.each do |party|
      party_already_exists = false
      party.email_addresses.map(&:email_address).each do |email|
        party_already_exists = true if Party.find_by_account_and_email_address(self, email)
      end
      next if party_already_exists
      new_party = Party.new()
      party.copy_to_account(new_party, self)
      party.groups.each do |group|
        new_group = self.groups.find_by_label(group.label)
        new_group ||= self.groups.create!(group.attributes_for_copy_to(self))
        new_party.groups << new_group
      end
    end
  end

  def copy_all_contacts_to!(options)
    logger.debug("==> Copying contacts to target account")
    target_acct = Account.find(options[:target_account_id])
    self.parties.each do |party|
      party_already_exists = false
      party.email_addresses.map(&:email_address).each do |email|
        party_already_exists = true if Party.find_by_account_and_email_address(target_acct, email)
      end
      next if party_already_exists
      new_party = Party.new()
      party.copy_to_account(new_party, target_acct)
      party.groups.each do |group|
        new_group = target_acct.groups.find_by_label(group.label)
        new_group ||= target_acct.groups.create!(group.attributes_for_copy_to(target_acct))
        new_party.groups << new_group
      end
    end
  end
  
  def copy_blogs_and_blog_posts_from!(options)
    domain = Domain.find(options[:source_domain_id])
    logger.debug("==> Copying blogs and blog posts from #{domain.name}")
    domain.account.blogs.each do |blog|
      next if self.blogs.find_by_label(blog.label)
      self.blogs.create!(blog.attributes_for_copy_to(self))
    end
    domain.account.blog_posts.each do |blog_post|
      existing_blog = self.blogs.find_by_label(blog_post.blog.label)
      existing_blog.posts.create!(blog_post.attributes_for_copy_to(self))
    end
  end

  # TODO: calling create! would be best but I don't want to lose the validation on blog and blog post
  # Missing author happened only on pushing template to stable anyways
  # Should probably make this method to be called for that purpose only
  def copy_all_blogs_and_blog_posts_to!(options)
    logger.debug("==> Copying blogs and blog posts to target account")
    target_acct = Account.find(options[:target_account_id])
    self.blogs.each do |blog|
      next if target_acct.blogs.find_by_label(blog.label)
      new_blog = target_acct.blogs.build(blog.attributes_for_copy_to(target_acct))
      new_blog.save(false)
    end
    self.blog_posts.each do |blog_post|
      existing_blog = target_acct.blogs.find_by_label(blog_post.blog.label)
      new_blog_post = existing_blog.posts.build(blog_post.attributes_for_copy_to(target_acct))
      new_blog_post.save(false)
    end
  end
  
  #Options: 
  # - create_dependencies: create any dependencies required by the actions, if it doens't exist in the account
  #     Example: Copying action "Add to Group 'XLsuite'" will create a group labeled "XLsuite" in the target account
  def copy_workflows_from!(options)
    domain = Domain.find(options[:source_domain_id])
    logger.debug("==> Copying workflows from #{domain.name}")
    domain.account.workflows.each do |workflow|
      new_workflow = self.workflows.create!(workflow.attributes_for_copy_to(self))
      new_workflow.copy_steps_from!(workflow, options)
    end
  end
  
  # TODO: should call create! here too but losing validation is no good too.....
  def copy_all_workflows_to!(options)
    logger.debug("==> Copying workflows to target account")
    target_acct = Account.find(options[:target_account_id])
    self.workflows.each do |workflow|
      t_workflow = target_acct.workflows.find_by_uuid(workflow.uuid)
      if t_workflow
        if options[:overwrite]
          t_workflow.attributes = workflow.attributes_for_copy_to(target_acct)
          t_workflow.save(false)
        end
      else      
        t_workflow = target_acct.workflows.build(workflow.attributes_for_copy_to(target_acct))
        t_workflow.save(false)
      end
      t_workflow.copy_steps_from!(workflow, options)
    end
  end
  
  def copy_feeds_from!(options)
    domain = Domain.find(options[:source_domain_id])
    logger.debug {"==> Copying feeds from #{domain.name}"}
    domain.account.feeds.each do |feed|
      #TODO: really this should be create! but right now it's only create because 
      #the modules might have feeds with the same label however, we can't deal with this scenario at the moment
      #need to implement an intelligent merger first
      self.feeds.create(feed.attributes_for_copy_to(self))
    end
    
    MethodCallbackFuture.create!(:models => [self.feeds], :account => domain.account, :method => :refresh)
  end

  def copy_all_feeds_to!(options)
    logger.debug("==> Copying feeds to target account")
    target_acct = Account.find(options[:target_account_id])
    self.feeds.each do |feed|
      #TODO: really this should be create! but right now it's only create because 
      #the modules might have feeds with the same label however, we can't deal with this scenario at the moment
      #need to implement an intelligent merger first
      target_acct.feeds.create(feed.attributes_for_copy_to(target_acct))
    end    
    MethodCallbackFuture.create!(:models => [self.feeds], :account => target_acct, :method => :refresh) unless self.feeds.empty?
  end
  
  def copy_all_email_templates_from!(options)
    domain = Domain.find(options[:source_domain_id])
    logger.debug {"==> Copying email templates from #{domain.name}"}
    domain.account.templates.each do |template|
      next if self.templates.find_by_label(template.label)
      self.templates.create!(template.attributes_for_copy_to(self))
    end
  end
  
  def copy_all_email_templates_to!(options)
    logger.debug("==> Copying email templates to target account")
    target_acct = Account.find(options[:target_account_id])
    self.templates.each do |template|
      next if target_acct.templates.find_by_label(template.label)
      new_template = target_acct.templates.new(template.attributes_for_copy_to(target_acct))
      new_template.save(false)
    end
  end
  
  def copy_all_links_to!(options)
    logger.debug("==> Copying links to target account")
    target_acct = Account.find(options[:target_account_id])
    self.links.each do |link|
      new_link = target_acct.links.new(link.attributes_for_copy_to(target_acct))
      new_link.approved = link.approved
      new_link.save(false)
      new_link.reload.copy_assets_from!(link)
    end
  end
  
  def grant_all_permissions_to_owner
    self.owner.grant_all_permissions
  end
  
  def profile_root_product_category
    self.get_config(:profile_root_product_category)
  end
  
  def find_domain_subscription_with_empty_slot
    # find if there is a missing spot otherwise use the last spot, missing spot == missing bucket based on the quantity configuration
    bucket = self.find_next_available_domain_subscription_bucket
=begin
    if bucket == 0
      return self.create_free_domain_subscription
    end
    case bucket
    when 0..2
      raise "Somebody is trying to hack!" if bucket != level
    when 3
      raise "Somebody is trying to hack!" unless [2, 3, 4].index(level)
    end
=end
    # look for existing domain_subscriptions with the specified bucket whose number_of_domains is bigger than the domains count of the domain subscription
    self.domain_subscriptions.find(:all, :conditions => {:bucket => bucket, :cancelled_at => nil}).detect do |ds|
       ds.number_of_domains > ds.domains.count
    end
  end
  
  def find_or_create_domain_subscription(level)
    level = level.to_i
    raise "Somebody is trying to hack!" unless (0..4).include?(level)
    
    bucket = self.find_next_available_domain_subscription_bucket
    domain_subscription = self.find_domain_subscription_with_empty_slot
    
    unless domain_subscription
      t_account = self.master? ? self : self.parent
      ActiveRecord::Base.transaction do
        order = t_account.orders.create!(:account => t_account,
          :date => Time.now, 
          :notes => "Domain registration for [PLEASE INPUT DOMAIN NAME HERE]",
          :invoice_to => self.owner
        )

        ds_product = t_account.get_config("domain_subscription_level_#{level}_product")
        order.lines.create!(:target_id => ds_product.dom_id, :account => t_account)

        domain_subscription = self.domain_subscriptions.create!(
            :bucket            => bucket,
            :number_of_domains => t_account.get_config("domain_subscription_level_#{level}_quantity"),
            :pay_period        => ds_product.pay_period,
            :free_period       => ds_product.free_period,
            :amount            => ds_product.retail_price,
            :order             => order)
      end
    end
    
    domain_subscription
  end
  
  def create_free_domain_subscription
    self.domain_subscriptions.create!(
        :bucket => 0, :number_of_domains => 1,
        :pay_period => nil, :free_period => nil,
        :amount => Money.zero, :order => nil)
  end
  
  def find_next_available_domain_subscription_products
    products_with_level = []
    next_available_bucket = self.find_next_available_domain_subscription_bucket
    t_account = self.master? ? self : self.parent
    case next_available_bucket
    when 1, 2
      products_with_level << {
        :level => next_available_bucket,
        :product => t_account.get_config("domain_subscription_level_" + next_available_bucket.to_s + "_product"),
        :number_of_domains => t_account.get_config("domain_subscription_level_" + next_available_bucket.to_s + "_quantity")
      }
    when 3
      [2,3,4].each do |i|
        products_with_level << {
          :level => i,
          :product => t_account.get_config("domain_subscription_level_" + i.to_s + "_product"),
          :number_of_domains => t_account.get_config("domain_subscription_level_" + i.to_s + "_quantity")
        }
      end
    else
      raise "This should never happen at all"
    end
    products_with_level
  end
  
  # TODO: what do I do about existing accounts?
  def find_next_available_domain_subscription_bucket
    t_account = self.master? ? self : self.parent
    return 0 if self.domains.in_bucket(0).count.zero? # most of the time this case would not be met
    return 1 if self.domains.in_bucket(1).count < t_account.get_config(:number_of_domains_for_level_1)
    return 2 if self.domains.in_bucket(2).count < t_account.get_config(:number_of_domains_for_level_2)
    3
  end
  
  def find_or_create_party_by_email_address!(email_address, attrs={})
    party = Party.find_by_account_and_email_address(self, email_address)
    unless party
      party = self.parties.build
      party.set_name(attrs.delete(:name))
      party.attributes = attrs
      party.save!
      email = party.main_email
      email.account = self
      email.email_address = email_address
      email.save!
    end
    party
  end
  
  def create_account_module_subscription!(account_template, modules)
    account_template_future = nil
    ActiveRecord::Base.transaction do
      master_account = self.class.find_by_master(true)
      i_modules = modules
      i_modules += account_template.selected_modules if account_template
      i_modules.uniq!
      raise "Either account template or account module need to be provided to create an account module subscription" if i_modules.empty? && account_template.blank?
      acct_mod_subscription = AccountModuleSubscription.create!(
        :account => self,
        :minimum_subscription_fee => AccountModule.count_minimum_subscription_fee(i_modules),
        :installed_account_modules => i_modules)
      payment_description = []
      unless i_modules.empty?
        payment_description << i_modules.map(&:humanize).map(&:downcase).join(', ')
      end      
      if account_template
        payment_description << "#{account_template.name} suite"
        installed_account_template = self.installed_account_templates.create!(
          :account_template => account_template,
          :subscription_markup_fee => account_template.subscription_markup_fee,
          :setup_fee => account_template.setup_fee,
          :account_module_subscription => acct_mod_subscription) 
        account_template_future = AccountTemplateInstallFuture.create!(:owner => self.owner, :account => self, :account_template_id => account_template.id, :priority => 75)
      end
      payment_amount = (account_template ? account_template.subscription_fee : acct_mod_subscription.minimum_subscription_fee) 
      payment = Payment.create!(:account => master_account, :payment_method => "paypal",
        :amount => payment_amount, :payer => self.owner, 
        :description => ("Subscription for #{self.domains.first.name} includes " + payment_description.join(" AND ")))
      payable = Payable.create!(:account => master_account, :amount => payment_amount,
        :payment => payment, :subject => acct_mod_subscription)
    end
    return account_template_future
  end
  
  def set_parent
    return unless self.parent.nil?
    parent_domain = nil
    if self.referral_domain
      parent_domain = Domain.find_by_name(self.referral_domain)
    else
      parent_domain_name = self.domains.reload.first.name.split(".")
      parent_domain_name.shift
      parent_domain = Domain.find_by_name(parent_domain_name.join("."))
    end
    parent_domain = Domain.find_by_name("xlsuite.com") if parent_domain.blank?
    self.parent = parent_domain.account
  end
  
  def has_paypal?
    !self.configurations.find_all_by_name("paypal_business").map(&:str_value).reject{|e| e.blank?}.empty?
  end
  
  def has_payment_gateway?
    username_configs = self.configurations.find_all_by_name("payment_gateway_username").map(&:str_value).reject{|e| e.blank?}
    password_configs = self.configurations.find_all_by_name("payment_gateway_password").map(&:str_value).reject{|e| e.blank?}
    if !username_configs.empty? && !password_configs.empty?
      return true
    else
      return false
    end
  end
  
  def update_account_owner_info_in_master_account
    return if self.new_record? || self.master?
    account_owner = self.owner
    Account.find_all_by_master(true).each do |master_account|
      new_party = nil
      account_owner.email_addresses.map(&:email_address).each do |email_address|
        new_party = Party.find_by_account_and_email_address(master_account, email_address)
      end

      if new_party
        if new_party.updated_at < account_owner.updated_at
          %w(first_name last_name middle_name company_name position honorific timezone 
          birthdate_day birthdate_month birthdate_year).each do |attribute|
            new_party.send("#{attribute}=", account_owner.send(attribute)) if new_party.respond_to?("#{attribute}=")
          end
        end
      else
        new_party = master_account.parties.create!
        %w(first_name last_name middle_name company_name position honorific timezone 
        birthdate_day birthdate_month birthdate_year).each do |attribute|
          new_party.send("#{attribute}=", account_owner.send(attribute)) if new_party.respond_to?("#{attribute}=")
        end
      end
      
      new_party.tag_list += " account_owner"
      new_party.save!
      
      default_group_label = master_account.get_config(:account_owner_default_group_label)
      group = master_account.groups.find_by_label(default_group_label)
      group.join!(new_party)
      
      contact_route_attributes = nil
      t_contact_route = nil
      [:email_addresses, :links, :addresses, :phones].each do |contact_routes|
        account_owner.send(contact_routes).each do |contact_route|
          contact_route_attributes = contact_route.dup.attributes
          contact_route_attributes.delete_if{|k,v| v.blank?}
          contact_route_attributes.delete("name")
          contact_route_attributes.delete("position")
          t_contact_route = ContactRoute.find(:first, 
             :conditions => contact_route_attributes.merge(:routable_type => new_party.class.name, 
             :routable_id => new_party.id, :account_id => master_account.id))
          unless t_contact_route
            t_contact_route = new_party.send(contact_routes).build(contact_route_attributes)
            t_contact_route.account = master_account
            t_contact_route.save!
          end  
        end
      end
    end
    true
  end  
  
  # This method is used to copy all data of a profile to an account owner
  # The data includes avatar, products and feeds
  def copy_profile_to_owner!(options)
    ActiveRecord::Base.transaction do
      owner_party = self.owner
      # destroy the existing profile of the account owner
      owner_party.profile.destroy if owner_party.profile

      # find profile to copy from
      profile_id = options[:profile_id].to_i
      profile = Profile.find(profile_id)

      # grab attributes of the source profile and remove average_rating, created_at and updated_at
      # copying average_rating, created_at and updated_at do not make sense
      # it's a different profile so those attributes must not carry over
      profile_attrs = profile.attributes
      profile_attrs.stringify_keys!
      profile_attrs.delete("average_rating")
      profile_attrs.delete("created_at")
      profile_attrs.delete("updated_at")
      # create new profile based on previous attributes
      owner_profile = Profile.new(profile_attrs)
      owner_profile.account = self
      owner_profile.save!

      # update attributes of the account owner and assign the newly created profile to it
      owner_party.attributes = profile.to_party_attributes
      owner_party.profile_id = owner_profile.id
      owner_party.save!
      # copy all contact routes from the source profile to the account owner
      profile.copy_routes_to_party!(owner_party)
      # must do a reload here so that the next line "owner_party.copy_contact..." returns correct result
      owner_party.reload
      # copy contact routes of the account owner to his/her profile
      owner_party.copy_contact_routes_to_profile!
      
      # if the account owner profile has an avatar attached to it
      # create a new asset and assign it as the avatar of the profile
      if owner_profile.avatar
        new_avatar = self.assets.create!(owner_profile.avatar.attributes_for_copy_to(self))
        owner_profile.update_attribute(:avatar_id, new_avatar.id)
        owner_party.update_attribute(:avatar_id, new_avatar.id)
      end
      
      # copy products from the party of the source profile to the account owner
      s_attrs, t_product, new_asset = nil, nil, nil
      saved = false
      profile.party.products.each do |product|
        s_attrs = product.attributes_for_copy_to(self)
        t_product = self.products.build(s_attrs)
        t_product.owner = owner_party
        saved = t_product.save
        product.assets.each do |asset|
          new_asset = self.assets.create!(asset.attributes_for_copy_to(self))
          t_product.assets << new_asset
        end if saved
      end
      
      # copy feeds from the party of the source profile to the account owner
      t_feed = nil
      profile.party.feeds.each do |feed|
        s_attrs = feed.attributes_for_copy_to(self)
        s_attrs.delete("feed_id")
        s_attrs.delete("party_id")
        t_feed = self.feeds.build(s_attrs)
        owner_party.feeds << t_feed if t_feed.save
      end
    end
    true
  end
  
  def to_liquid
    AccountDrop.new(self)
  end
  
  def secure_xlsuite_subdomain
    domain_names = self.domains.all(:select => "name").map(&:name)
    domain_names.each do |domain_name|
      return domain_name if domain_name =~ /\A(?:[a-z0-9][-\w])*secure(?:[a-z0-9][-\w])*\.xlsuite\.com\Z/i
    end
    domain_names.each do |domain_name|
      return domain_name if domain_name =~ /\A(?:[a-z0-9][-\w]+)\.xlsuite\.com\Z/i
    end
    nil
  end
  
  def force_refresh_on_cached_pages!
    ActiveRecord::Base.transaction do
      CachedPage.delete_all(["account_id = ?", self.id])
    end
  end
  
  def force_refresh_on_cached_pages_with_fullslug!(options)
    ActiveRecord::Base.transaction do
      CachedPage.delete_all(["account_id = ? AND page_fullslug = ?", self.id, options[:fullslug]])
    end
  end
  
  def force_refresh_on_cached_page_stylesheets!
    CachedPage.delete_all(["account_id = ? AND page_fullslug LIKE '%.css'", self.id])
  end
  
  def force_refresh_on_cached_page_javascripts!
    CachedPage.delete_all(["account_id = ? AND page_fullslug LIKE '%.js'", self.id])
  end
  
  def email_addresses_with_smtp_access
    party_ids = SmtpEmailAccount.all(:select => "party_id", :conditions => {:account_id => self.id, :enabled => true}).map(&:party_id)
    EmailContactRoute.all(:select => "email_address", :conditions => {:routable_type => "Party", :routable_id => party_ids}).map(&:email_address).uniq.sort
  end
  
  protected
  def process_affiliate_account(affiliate_account)
    item = AffiliateAccountItem.new
    item.target = self
    item.affiliate_account = affiliate_account
    item.percentage = 40
    item.save!
    item_line = AffiliateAccountItemLine.new
    item_line.target = self
    item_line.affiliate_account_item = item
    item_line.quantity = 1
    item_line.commission_percentage = 40
    item_line.status = "Free trial"
    item_line.level = item.level
    item_line.save!
  end
  
  def available_names_by_role(role)
    domain_names = self.domains.find(:all, :order=> "name").map(&:name).reject(&:blank?)
    result = [] 
    domain_names.each do |domain_name|
      parts = domain_name.split(".")
      (0..parts.size).to_a.map {|index| parts[index..-1]}.reject(&:blank?).each do |domain_parts|
        candidate_name = domain_parts.join(".")
        result += Domain.find_all_by_role(role, :conditions => ["name = ?", "template.#{candidate_name}"])
        result += Domain.find_all_by_role(role, :conditions => ["name LIKE ?", "%.template.#{candidate_name}"], :order => "name")
        break unless result.blank?
      end      
    end
    result = result.flatten.compact.uniq
    return result unless result.blank?
    parts = "xlsuite.com".split(".")
    (0..parts.size).to_a.map {|index| parts[index..-1]}.reject(&:blank?).each do |domain_parts|
      candidate_name = domain_parts.join(".")
      result += Domain.find_all_by_role(role, :conditions => ["name = ?", "template.#{candidate_name}"])
      result += Domain.find_all_by_role(role, :conditions => ["name LIKE ?", "%.template.#{candidate_name}"], :order => "name")
      break unless result.blank?
    end      
    result.flatten.compact.uniq
  end

  def base_cost
    Configuration.get(:account_base_cost, self).to_money
  end

  def options_cost
    Money.zero
  end

  def set_confirmation_token
    return unless self.registering?
    self.confirmation_token = UUID.random_create.to_s
    self.confirmation_token_expires_at = Configuration.get(:confirmation_token_duration_in_seconds).from_now
  end

  def send_confirmation_email
    return unless self.registering?
    self.confirmation_url = self.confirmation_url.call(confirmation_token) if self.confirmation_url.respond_to?(:call)
    MethodCallbackFuture.create!(:account => self, :method => :send_confirmation_email_with_confirmation_url, 
      :priority => 1, :model => self, :params => {:url => self.confirmation_url})
  end
  
  def send_confirmation_email_with_confirmation_url(params)
    AdminMailer.deliver_account_confirmation_email(:route => self.owner.main_email,
      :domain_name => self.domains.first.name, :confirmation_url => params[:url])
  end

  def copy_configurations
    account_wide_configs = Configuration.find(:all, :conditions => {:account_id => nil, :account_wide => true})
    account_wide_configs.each do |config|
      new_config = config.class.create!(config.attributes.merge(:account_id => self.id))
      new_config.set_value!(config.value)
    end
  end
  
  def send_reminder_email_if_not_activated
    begin
      AdminMailer.deliver_account_not_activated_email(self) unless self.activated?
      true
    rescue
      false
    end
  end
  
  def send_expired_account_deleted_email
    return unless self.expires_at <= EXPIRED_ACCOUNT_DEADLINE_IN_MONTH.months.ago
    begin
      AdminMailer.deliver_expired_account_deleted_email(self)
      true
    rescue
      false
    end
  end
  
  def domain_names_as_text
    self.domains.map(&:name)
  end
  
  def account_owner_display_name_as_text
    return "" unless self.owner
    self.owner.display_name
  end
  
  def account_owner_email_as_text
    return "" unless self.owner
    self.owner.main_email.email_address
  end
  
  def due_date_as_text
    self.expires_at.strftime('%d/%m/%Y, %I:%M %p')
  end
  
  def cost_as_text
    self.cost.to_s
  end
end
