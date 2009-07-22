#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

require 'csv'

class Product < ActiveRecord::Base
  include XlSuite::Commentable
  include XlSuite::AccessRestrictions

  acts_as_taggable
  acts_as_fulltext %w(name most_recent_supplier_name in_stock on_order sold_to_date wholesale_price retail_price margin description), :weight => 50
  acts_as_reportable

  has_and_belongs_to_many :categories, :class_name => 'ProductCategory'
  
  has_many :providers
  has_many :suppliers, :through => :providers

  belongs_to :account

  belongs_to :creator, :class_name => 'Party', :foreign_key => :creator_id
  belongs_to :editor, :class_name => "Party", :foreign_key => :editor_id
  belongs_to :owner, :class_name => "Party", :foreign_key => :owner_id

  acts_as_money :retail_price, :wholesale_price, :wholesale_peak_price, :wholesale_low_price
  acts_as_period :free_period, :pay_period, :allow_nil => true

  ValidClassifications = %w(product service).freeze
  validates_inclusion_of :classification, :in => ValidClassifications

  before_validation Proc.new {|p| p.name = p.name.strip unless p.name.blank? }
  before_validation Proc.new {|p| p.domain_patterns = "**" if p.domain_patterns.blank? }

  validates_presence_of :name, :account_id
  validates_uniqueness_of :sku, :scope => [:account_id], :if => :sku?

  before_create :initialize_wholesale_peak_and_low_price

  before_save :update_creator_and_editor
  before_save :calculate_margin
  before_save :update_wholesale_peak_and_low_price
  
  serialize :bulk_rates, Hash

  has_many :views, :as => :attachable, :order => "position"
  has_many :assets, :through => :views
  has_many :pictures, :source => :asset, :through => :views, :order => "views.position", :conditions => 'assets.content_type LIKE "image/%"'
  alias_method :images, :pictures
  
  has_many :group_items, :as => :target, :dependent => :destroy
  has_many :groups, :through => :group_items, :source => :group, :order => "groups.name"
  
  acts_as_hashable :polygons, :as => :owner
  
  has_many :accessible_items, :class_name => "ProductItem"
  has_many :grant_objects, :class_name => "ProductGrant"
  has_many :accessible_assets, :through => :accessible_items, :source => :item, :source_type => "Asset"
  
  def picture_ids
    @image_ids || Product.connection.select_values(%Q~SELECT assets.id FROM assets INNER JOIN views ON assets.id = views.asset_id WHERE ((views.attachable_type = 'Product') AND (views.attachable_id = #{self.id})) ORDER BY views.position~)
  end
  alias_method :image_ids, :picture_ids
  
  after_save :update_image_ids
  
  def image_ids=(asset_ids)
    raise "image_ids= only takes in an array" unless asset_ids.kind_of?(Array)
    @image_ids = asset_ids
  end
  alias_method :picture_ids=, :image_ids=
  
  def after_initialize
    self.bulk_rates ||= {}
    self.bulk_rates[:apply_to_sales_events] = false
    self.bulk_rates[:apply_to_affiliations] = false
    self.bulk_rates[:apply_to_internet_orders] = false
  end
  
  def self.find_readable_by(party, query_params, search_options)
    group_ids = party.groups.find(:all, :select => "groups.id").map(&:id)
    product_ids = self.find(:all, :select => "#{self.table_name}.*",
      :joins => [%Q`LEFT JOIN authorizations ON authorizations.object_type="#{self.name}" AND authorizations.object_id=#{self.table_name}.#{self.primary_key}`, 
          %Q`LEFT JOIN groups ON groups.id=authorizations.group_id`].join(" "), 
      :conditions => "groups.id IS NULL OR groups.id IN (#{group_ids.join(",").blank? ? 0 : group_ids.join(",")})").map(&:id)
    self.search(query_params, search_options.merge(:conditions => "#{self.table_name}.#{self.primary_key} IN (#{product_ids.join(",")})"))
  end
  
  def self.count_readable_by(party, query_params)
    group_ids = party.groups.find(:all, :select => "groups.id").map(&:id)
    product_ids = self.find(:all, :select => "#{self.table_name}.*",
      :joins => [%Q`LEFT JOIN authorizations ON authorizations.object_type="#{self.name}" AND authorizations.object_id=#{self.table_name}.#{self.primary_key}`, 
          %Q`LEFT JOIN groups ON groups.id=authorizations.group_id`].join(" "), 
      :conditions => "groups.id IS NULL OR groups.id IN (#{group_ids.join(",").blank? ? 0 : group_ids.join(",")})").map(&:id)
    count_options = nil
    if query_params.blank?
      count_options = {:conditions => "#{self.table_name}.#{self.primary_key} IN (#{product_ids.join(",")})"}
    else
      count_options = {:conditions => "subject_type='#{self.name}' AND subject_id IN (#{product_ids.join(",")})"}
    end
    self.count_results(query_params, count_options)
  end
  
  def self.not_in_any_category(options={})
    conditions = options[:conditions]
    if conditions.empty?
      conditions = "product_id IS NULL"
    else
      case conditions
      when Array
        conditions[0] = conditions[0] + " AND product_id IS NULL"
      when String
        conditions = conditions + " AND product_id IS NULL"
      end
    end
    self.find(:all, :select => "products.*", :joins => "LEFT JOIN product_categories_products ON product_categories_products.product_id = products.id", 
      :conditions => conditions, :order => "products.name ASC")
  end
  
  def to_liquid
    ProductDrop.new(self)
  end

  def apply_to_sales_events=(status)
    self.bulk_rates[:apply_to_sales_events] = status ? true : false
  end

  def apply_to_sales_events
    self.bulk_rates[:apply_to_sales_events]
  end
  
  def apply_to_affiliations=(status)
    self.bulk_rates[:apply_to_affiliations] = status ? true : false
  end

  def apply_to_affiliations
    self.bulk_rates[:apply_to_affiliations]
  end
  
  def apply_to_internet_orders=(status)
    self.bulk_rates[:apply_to_internet_orders] = status ? true : false
  end

  def apply_to_internet_orders
    self.bulk_rates[:apply_to_internet_orders]
  end
  
  # TODO : this is not completed!!!
  def sale_events
    categories_ids = self.categories.map(&:id)
    sale_events_ids = []
    sale_events_ids += self.account.all_products_sale_event_items.find(:all, :select => "DISTINCT sale_event_id").map(&:sale_event_id)
    logger.debug("^^^sale_events_ids = #{sale_events_ids.inspect}")
    sale_events = []
    sale_events += self.account.sale_events.find(sale_events_ids)
    sale_events
  end
  
  # TODO: THIS IS NOT IMPLEMENTED
  def latest_po_status
    "Not implemented"
  end
  
  # TODO: THIS IS NOT IMPLEMENTED
  def last_po_arrived_at
    nil
  end
  
  def set_main_image(image_id)
    image_id_clone = nil
    if !image_id.kind_of?(Fixnum)
      image_id_clone = image_id.clone.to_i
    else
      image_id_clone = image_id.to_i
    end
    image = self.account.assets.find(image_id_clone)
    product_view = self.views.find(:first, :conditions => ["views.asset_id = ?", image_id_clone])
    if product_view
      product_view.move_to_top
    else
      self.assets << image
      product_view = self.views.find(:first, :order => "position DESC")
      product_view.move_to_top
    end
    product_view
    rescue ActiveRecord::RecordNotFound
      return nil
  end
  
  alias_method :main_image=, :set_main_image
  
  def main_image_id
    product_view = self.views.find(:first, :order => "position ASC")
    return nil unless product_view
    return product_view.asset_id
  end
  
  def main_image
    product_view = self.views.find(:first, :order => "position ASC")
    return nil unless product_view
    return product_view.asset
  end
  
  def attributes_for_copy_to(account)
    account_owner_id = account.owner ?  account.owner.id : nil
    account_owner_name = account.owner ? account.owner.display_name : nil

    attributes = self.attributes.dup.symbolize_keys.merge(:account_id => account.id, :sold_to_date => 0, :most_recent_supplier_id => nil, :on_order => nil,
                              :creator_id => account_owner_id, :creator_name => account_owner_name, :editor_id => nil, :editor_name => nil,
                              :domain_patterns => "**", :tag_list => self.tag_list, :owner_id => nil, :owner => nil, :private => false)
    attributes.delete(:product_id)
    attributes.delete(:product_category_id)
    attributes
  end
  
  def copy_assets_from!(product)
    unless product.assets.blank?
      product.assets.each do |asset|
        full_path = asset.file_directory_path.split("/")
        name = full_path.pop
        path = full_path.join("/")
        existing_asset = self.account.assets.find_by_path_and_filename(path, name)
        existing_asset = self.account.assets.create(asset.attributes_for_copy_to(self.account)) unless existing_asset
        
        unless self.views.map(&:asset_id).include?(existing_asset.id)
          view = self.views.build(:asset_id => existing_asset.reload.id)
          view.classification = "Image"
          view.save!
        end
      end
    end
  end
  
  def comment_approval_method
    if self.deactivate_commenting_on && (self.deactivate_commenting_on <= Date.today)
      return "no comments" 
    else
      self.read_attribute(:comment_approval_method)
    end
  end
  
  def attach_expiring_items_to!(party, options={})
    started_at = options[:started_at] || Time.now.utc
    item, expiring_party_item = nil, nil
    out = []
    self.accessible_items.each do |product_item|
      item = product_item.item
      expiring_party_item = party.expiring_items.find(:first, :conditions => {:item_type => item.class.name, :item_id => item.id})
      if expiring_party_item
        attrs = options.clone
        attrs.each_pair do |k,v|
          attrs.delete(k) unless expiring_party_item.respond_to?(k.to_s+"=")
        end
        expiring_party_item.attributes = attrs
        expiring_party_item.save!
      else
        expiring_party_item = party.expiring_items.create!(:item => product_item.item, 
          :started_at => started_at, :expired_at => options[:expired_at],
          :created_by => options[:created_by], :updated_by => options[:updated_by])
      end
      out << expiring_party_item
    end
    out.compact
  end
  
  def add_to_category_ids!(ids)
    t_categories = self.account.product_categories.find(ids)
    t_category_ids = []
    t_categories.each do |category|
      t_category_ids += category.ancestors.map(&:id)
      t_category_ids << category.id
    end
    t_category_ids.reject(&:blank?)
    t_category_ids.uniq!
    
    self.category_ids += (self.category_ids + t_category_ids).uniq
    self.save!
  end
  
  def send_comment_email_notification(comment)
    if self.creator && self.creator.confirmed? && self.creator.product_comment_notification?
      AdminMailer.deliver_comment_notification(comment, "product \"#{self.name}\"", self.creator.main_email.email_address)
    end
  end
  
  protected

  def initialize_wholesale_peak_and_low_price
    self.wholesale_peak_price = self.wholesale_low_price = self.wholesale_price
  end

  def update_creator_and_editor
    self.creator_name = Party.find(self.creator_id).display_name unless self.creator_id.blank?
    self.editor_name = Party.find(self.editor_id).display_name unless self.editor_id.blank?
    rescue ActiveRecord::RecordNotFound
  end

  def calculate_margin
    wholesale_cents = self.wholesale_price ? self.wholesale_price.cents : 0 
    retail_cents = self.retail_price ? self.retail_price.cents : 0
    if wholesale_cents == retail_cents || wholesale_cents == 0
      self.margin = 0
      return true
    end
    self.margin = (retail_cents - wholesale_cents) * 100.000 / wholesale_cents
  end

  def update_wholesale_peak_and_low_price
    wholesale_price_cents = self.wholesale_price ? self.wholesale_price.cents : 0
    wholesale_peak_price_cents = self.wholesale_peak_price ? self.wholesale_peak_price.cents : 0
    wholesale_low_price_cents = self.wholesale_low_price ? self.wholesale_low_price.cents : 0
    self.wholesale_peak_price = Money.new(wholesale_price_cents) if wholesale_price_cents > wholesale_peak_price_cents
    self.wholesale_low_price = Money.new(wholesale_price_cents) if wholesale_price_cents < wholesale_low_price_cents
  end
  
  def update_image_ids
    return unless @image_ids
    self.class.transaction do
      self.views.each do |view|
        asset = view.asset
        view.destroy if asset.content_type =~ /^image/i
      end
      @image_ids.each do |asset_id|
        asset = self.account.assets.find(asset_id)
        self.views.create(:asset => asset) if asset.content_type =~ /^image/i
      end
    end
  end
end
