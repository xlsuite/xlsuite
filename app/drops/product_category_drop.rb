#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ProductCategoryDrop < Liquid::Drop
  attr_reader :product_category
  delegate :id, :name, :children, :parent, :label, :products, :to => :product_category

  def initialize(product_category)
    @product_category = product_category
  end

  def picture
    @picture ||= PictureDrop.new(self.product_category.picture)
  end

  def description
    product_category.web_copy.blank? ? (product_category.description || "") : product_category.web_copy
  end  
end
