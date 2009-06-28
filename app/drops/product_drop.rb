#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ProductDrop < Liquid::Drop
  attr_reader :product
  delegate :id, :name, :product_no, :categories, :tags, :creator, :editor, :owner,
      :sku, :dom_id, :pictures, :free_period, :created_at, :updated_at, :polygons,
      :pay_period_unit, :pay_period_length, :free_period_unit, :free_period_length, 
      :approved_comments_count, :unapproved_comments_count, :description, 
      :creator_id, :editor_id, :owner_id, :main_image, :external_url, 
      :accessible_items, :accessible_assets, :private, :to => :product

  def initialize(product)
    @product = product
  end
  
  def wholesale_price
    MoneyDrop.new(self.product.wholesale_price)
  end
  
  def retail_price
    MoneyDrop.new(self.product.retail_price)
  end

  def unit_price
    self.retail_price
  end

  def plain_retail_price
    self.product.retail_price.format(:with_currency)
  end

  def repeat_interval
    self.product.pay_period.to_s.sub(/^1\s/, "")
  end

  def web_copy
    template = Liquid::Template.parse(self.product.web_copy)
    template.render(context)
  end
  
  def pay_period
    %Q`#{self.pay_period_length} #{self.pay_period_unit}`
  end
  
  def free_period
    %Q`#{self.free_period_length} #{self.free_period_unit}`
  end

  def approved_comments
    self.product.approved_comments unless self.product.hide_comments
  end

  def comments_hidden?
    self.product.hide_comments
  end
  
  def average_rating
    (self.product.average_comments_rating * 10).round.to_f / 10
  end

  def comments_always_approved
    self.product.comment_approval_method =~ /always approved/i ? true : false
  end

  def comments_moderated
    self.product.comment_approval_method =~ /^moderated$/i ? true : false
  end
  
  def comments_off
    self.product.comment_approval_method =~ /no comments/i ? true : false
  end
  
  def category_ids
    self.product.category_ids.join(",")
  end
  
  def purchased_by_user
    return false unless self.context && self.context["user"] && self.context["user"].party
    return true if self.context["user"].party.purchased_products.include?(self.product)
    return false
  end
end
