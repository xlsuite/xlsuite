#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ProductSaleEventItem < SaleEventItem
  belongs_to :item, :polymorphic => true

  delegate :wholesale_price, :retail_price, :to => :item

  before_save :set_sale_price
  
  before_save :update_discount_and_sale_price
  before_save :calculate_margin

  acts_as_money :sale_price

  def to_json(hash={})
    out = {:id => self.id, :name => item.name, :target_id => item.dom_id,
      :wholesale_price => self.wholesale_price.to_s, :retail_price => self.retail_price.to_s, :sale_price => self.sale_price.to_s,
      :discount => self.discount.to_s, :margin => self.margin.to_s}
    out.merge!(hash)
    out.to_json
  end
  
  def margin=(input)
    self.send(:write_attribute, :margin, input)
    calculate_sale_price_and_discount_based_on_margin
  end

  protected
  
  def set_sale_price
    self.sale_price = Money.new(self.retail_price.cents) if self.new_record?
  end
  
  def update_discount_and_sale_price
    if self.new_record?
      update_discount
      return true
    end
    old_obj = self.class.find(self.id)
    set_sale_price if !(self.item_type == old_obj.item_type && self.item_id == old_obj.item_id)
    if old_obj.sale_price != self.sale_price || self.class_changed?
      update_discount
      return true
    end 
    update_sale_price if old_obj.discount != self.discount  
  end
  
  def update_discount
    retail_price_cents = self.retail_price.cents
    if retail_price_cents == 0
      self.discount = 0
      return true
    end
    self.discount = (retail_price_cents - self.sale_price.cents) * 100.0 / retail_price_cents
  end
  
  def update_sale_price
    self.sale_price = Money.new((self.retail_price.cents * (100.0 - self.discount.to_f) / 100.0).to_i)
  end

  def calculate_margin
    wholesale_cents = self.wholesale_price.cents
    sale_cents = self.sale_price.cents
    if sale_cents > wholesale_cents
      set_sale_price
      sale_cents = self.sale_price.cents 
    end
    if wholesale_cents == sale_cents || wholesale_cents == 0
      self.margin = 0
      return true
    end
    self.margin = (sale_cents - wholesale_cents) * 100.000 / wholesale_cents
  end
  
  def calculate_sale_price_and_discount_based_on_margin
    wholesale_price_cents = self.wholesale_price.cents
    self.sale_price = Money.new(wholesale_price_cents * (100 + self.margin.to_f) / 100.0)
    update_discount
  end
end
