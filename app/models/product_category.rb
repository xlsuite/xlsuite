#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ProductCategory < ActiveRecord::Base
  acts_as_reportable
  acts_as_taggable
  acts_as_tree :order => 'name'

  has_and_belongs_to_many :products, :order => 'LOWER(name)'
  has_and_belongs_to_many :parties
  
  validates_presence_of :name, :label, :account_id
  validates_length_of :name, :maximum => 60
  validates_uniqueness_of :label, :scope => :account_id
  validates_format_of :label, :with => /\A[-\w]+\Z/i, :message => "can contain only a-z, A-Z, 0-9, _ and -, cannot contain space(s)"
  
  belongs_to :avatar, :class_name => "Asset", :foreign_key => "avatar_id"
  belongs_to :account

  before_validation :set_name_if_blank
  after_save :update_avatar_filename

  before_validation {|pc| pc.account = pc.parent.account if pc.parent}
  before_validation {|pc| pc.avatar.account = pc.account if pc.avatar}

  alias_method :real_picture=, :avatar=
  def avatar=(avatar_or_io)
    case avatar_or_io
    when Asset, NilClass
      p = avatar_or_io
    else
      return if avatar_or_io.length.zero?
      p = self.account.assets.build(:uploaded_data => avatar_or_io)
      p.save!
    end

    self.real_picture = p
  end

  def to_liquid
    ProductCategoryDrop.new(self)
  end

  def name(traverse=false)
    return super unless traverse
    return super if parent.blank?
    "#{self.parent.name(true)} / #{super}"
  end

  def name_to_params(traverse=true)
    name(traverse).split(' / ')
  end

  def destroyed?
    false
  end

  def random_products(count)
    return self.products[0, count]
  end

  def self.roots
    find(:all, :conditions => 'parent_id IS NULL', :order => 'name')
  end

  def self.reloadable?
    false
  end

  def _dump(depth)
    self.id.to_s
  end

  def append_to(result)
    result << self
    self.children.each do |pc|
      pc.append_to(result)
    end
  end

  def to_liquid
    ProductCategoryDrop.new(self)
  end

  def to_node
    s = self.children.empty? ? '' : "(#{self.children.length} subcategories)"
    node = {
      :id => self.id,
      :text => "#{self.name} | #{self.label}",
      :tag_list => self.tag_list
    }
    if (self.children.empty?)
      node[:children] = []
      #node[:leaf] = true
    else
      node[:children] = self.children.collect(&:to_node)
    end
    
    return node
  end
  
  def all_children
    c = self.children
    self.children.each do |gc|
      c += gc.all_children
    end 
    c
  end
  
  def self_and_all_children
    [self, self.all_children].flatten
  end
  
  def attributes_for_copy_to(account)
    attributes = self.attributes.dup.merge(:account_id => account.id, :parent_id => nil, :avatar_id => nil)
 
    avatar = account.assets.create!(self.avatar.attributes_for_copy_to(account)) if self.avatar
    attributes.merge!(:avatar_id => avatar.blank? ? nil : avatar.reload.id ) 
    attributes
  end
  
  def copy_products_and_subcategories_from_product_category!(category)
    category.products.each do |product|
      new_product = self.account.products.find(:first, :conditions => {:name => product.name, :owner_id => nil})
      new_product ||= self.products.build(product.attributes_for_copy_to(self.account))

      new_product.category_ids = new_product.category_ids << self.id
      new_product.save!

      new_product.copy_assets_from!(product)
    end

    category.children.each do |subcategory|
      new_category = self.account.product_categories.find_by_name(subcategory.name)
      new_category ||= self.account.product_categories.build(subcategory.attributes_for_copy_to(self.account))

      new_category.parent_id = self.id
      new_category.save!
      new_category.copy_products_and_subcategories_from_product_category!(subcategory)
    end
  end
  
  def self_and_children_products_count
    pcs = [self] 
    pcs = pcs + self.children unless self.children.blank?
    product_ids = ActiveRecord::Base.connection.select_values("SELECT product_id FROM product_categories_products WHERE product_category_id IN (#{pcs.map(&:id).join(',')})")
    Product.count(:all, :conditions => {:id => product_ids})    
  end
  
  def self_and_children_products
    pcs = [self] 
    pcs = pcs + self.children unless self.children.blank?
    product_ids = ActiveRecord::Base.connection.select_values("SELECT product_id FROM product_categories_products WHERE product_category_id IN (#{pcs.map(&:id).join(',')})")
    Product.find(:all, :conditions => {:id => product_ids}, :order => "LOWER(name) ASC")  
  end
  
  class << self
    def self._load(id)
      self.find(id)
    end

    def self.tree
      returning [] do |result|
        self.roots.each do |pc|
          pc.append_to(result)
        end
      end
    end
  end

  protected
  def set_name_if_blank
    return true unless self.name.blank?
    self.name = self.label.humanize
  end
  
  def update_avatar_filename
    return if self.avatar.nil?
    self.avatar.filename = self.name
    self.avatar.save
  end
end
