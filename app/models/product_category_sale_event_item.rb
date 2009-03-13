#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ProductCategorySaleEventItem < SaleEventItem
  belongs_to :item, :polymorphic => true

  def wholesale_price
    nil
  end
  
  def retail_price
    nil
  end
  
  def sale_price
    nil
  end
  
  def margin
    return self.discount unless self.discount > 0
    self.discount * -1
  end
  
  def to_json(hash={})
    out = {:id => self.id, :name => self.item.name, :target_id => self.item.dom_id,
      :wholesale_price => "", :retail_price => "", :sale_price => "",
      :discount => self.discount.to_s, :margin => self.margin.to_s}
    out.merge!(hash)
    out.to_json
  end  
end
