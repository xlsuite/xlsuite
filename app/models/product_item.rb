#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ProductItem < ActiveRecord::Base
  belongs_to :product
  belongs_to :item, :polymorphic => true
  
  validates_uniqueness_of :product_id, :scope => [:item_type, :item_id]
  
  after_create :after_create_callbacks
  after_destroy :after_destroy_callbacks
  
  protected
  def after_create_callbacks
    case self.item
    when Asset
      self.item.update_attribute(:private, true)
    when Group
      self.item.update_attribute(:private, true)
    when Blog
      self.item.update_attribute(:private, true)
    else
      raise StandardError, "Item type not supported"
    end
  end
  
  def after_destroy_callbacks
    case self.item
    when Asset
      other_product_items = ProductItem.all(:select => "id", :conditions => {:item_type => self.item.class.name, :item_id => self.item.id})
      self.item.update_attribute(:private, false) if other_product_items.empty?
    when Group
      other_product_items = ProductItem.all(:select => "id", :conditions => {:item_type => self.item.class.name, :item_id => self.item.id})
      self.item.update_attribute(:private, false) if other_product_items.empty?
    when Blog
      other_product_items = ProductItem.all(:select => "id", :conditions => {:item_type => self.item.class.name, :item_id => self.item.id})
      self.item.update_attribute(:private, false) if other_product_items.empty?
    else
      raise StandardError, "Item type not supported"
    end
  end
end
