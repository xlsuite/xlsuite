#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ProductCategoryDrop < Liquid::Drop
  attr_reader :product_category
  delegate :id, :name, :children, :ancestors, :siblings, :parent, :label, :avatar, 
           :to => :product_category

  def initialize(product_category)
    @product_category = product_category
  end

  alias_method :main_image, :avatar
  alias_method :picture, :avatar

  def products
    product_ids = ActiveRecord::Base.connection.select_values("SELECT product_id FROM product_categories_products WHERE product_category_id = #{self.product_category.id}")
    Product.find(:all, :conditions => {:id => product_ids}, :order => "LOWER(name) ASC")
  end

  def description
    product_category.web_copy.blank? ? (product_category.description || "") : product_category.web_copy
  end  
end
