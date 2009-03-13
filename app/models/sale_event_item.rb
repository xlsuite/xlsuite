#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class SaleEventItem < ActiveRecord::Base
  belongs_to :account
  validates_presence_of :account_id

  belongs_to :sale_event
  
  attr_accessor :class_changed

  def sale_price=(input)
  end
  
  def update_class_and_target(target)
    return if self.new_record?
    target_id = target.split("_").last
    type, item_type, item_id = nil, nil, nil
    case target
    when /^all_products/i
      type = "AllProductsSaleEventItem"
      item_type = nil
      item_id = nil
    when /^product_category/i
      type = "ProductCategorySaleEventItem"
      item_type = "ProductCategory"
      item_id = target_id.to_i
    when /^product/i
      type = "ProductSaleEventItem"
      item_type = "Product"
      item_id = target_id.to_i
    end
    if item_type
      item_type = '"' + item_type + '"'
    else
      item_type = "NULL"
    end
    item_id = "NULL" unless item_id
    # TODO: is there a better way to implement this? need to use execute to skip callbacks
    ActiveRecord::Base.connection.execute("UPDATE sale_event_items SET `type`='#{type}', `item_type`=#{item_type}, `item_id`=#{item_id} WHERE `id`=#{self.id}")
  end

  def self.construct(params)
    raise "Need to pass in target" if params[:target].blank?
    target = params.delete(:target)
    target_id = target.split("_").last
    sale_event_item = nil
    case target
    when /^all_products$/i
      sale_event_item = AllProductsSaleEventItem.new
      sale_event_item.item_type = nil
      sale_event_item.item_id = nil
    when /^product_category/i
      sale_event_item = ProductCategorySaleEventItem.new
      sale_event_item.item = ProductCategory.find(target_id.to_i)
    when /^product/i
      sale_event_item = ProductSaleEventItem.new
      sale_event_item.item = Product.find(target_id.to_i)
    end
    
    sale_event_item.attributes = params
    
    sale_event_item
  end
  
  def class_changed?
    !@class_changed.blank?
  end
end
