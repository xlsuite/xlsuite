#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class SaleEvent < ActiveRecord::Base
  belongs_to :account
  validates_presence_of :account_id

  include XlSuite::AccessRestrictions
  acts_as_taggable

  has_many :items, :class_name => "SaleEventItem", :dependent => :destroy

  belongs_to :creator, :class_name => "Party", :foreign_key => :creator_id
  belongs_to :editor, :class_name => "Party", :foreign_key => :editor_id
  
  validates_presence_of :name
  validates_uniqueness_of :name, :scope => [:account_id]
  
  before_save :update_creator_and_editor
  
  def construct_item(params)
    sale_event_item = SaleEventItem.construct(params.merge(:account_id => self.account_id))
    sale_event_item.sale_event_id = self.id
    sale_event_item
  end
  
  def to_json
    timestamp_format = "%d/%m/%Y"
    {:id => self.id,
      :object_id => self.dom_id,
      :name => self.name, 
      :start_date => self.starts_at.strftime(timestamp_format),
      :end_date => self.ends_at.strftime(timestamp_format),
      :total_products => self.total_products,
      :average_discount => self.average_discount.to_s,
      :average_margin => self.average_margin.to_s,
      :total_sales => self.total_sales.to_s, 
      :total_profit => self.total_profit.to_s
    }.to_json
  end

  protected
  
  def update_creator_and_editor
    self.creator_name = Party.find(self.creator_id).display_name unless self.creator_id.blank?
    self.editor_name = Party.find(self.editor_id).display_name unless self.editor_id.blank?
  end
end
