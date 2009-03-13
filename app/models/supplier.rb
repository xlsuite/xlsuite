#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Supplier < ActiveRecord::Base
  belongs_to :account
  belongs_to :supplier_entity, :class_name => "Entity", :foreign_key => :entity_id
  
  has_many :providers
  has_many :products, :through => :providers

  include XlSuite::AccessRestrictions
  acts_as_taggable

  belongs_to :creator, :class_name => "Party", :foreign_key => :creator_id
  belongs_to :editor, :class_name => "Party", :foreign_key => :editor_id

  before_save :update_creator_and_editor
  before_save :save_entity

  validates_presence_of :account_id

  attr_accessor :name_changed, :description_changed, :phone_changed, :address_changed, :email_changed, :link_changed
  
  %w(name description phone address email link).each do |attr_name|
    class_eval <<-EOF
      def #{attr_name}=(attrs)
        self.entity.#{attr_name} = attrs
        self.#{attr_name}_changed = true
      end

      def #{attr_name}
        self.entity.#{attr_name}
      end
      
      def #{attr_name}_changed?
        !self.#{attr_name}_changed.blank?
      end
    EOF
  end
  
  def entity
    self.supplier_entity || self.build_supplier_entity(:classification => "Supplier", :account => self.account)
  end

  protected
  
  def save_entity
    if (self.new_record? || self.name_changed? || self.description_changed? || \
        self.phone_changed? || self.address_changed? || self.email_changed? || self.link_changed?)
      entity = self.entity
      entity.account = self.account
      entity.save!
      self.entity_id = entity.id
    end
  end

  def update_creator_and_editor
    unless self.creator_id.blank?
      creator_name = Party.find(self.creator_id).display_name 
      self.creator_name = creator_name
      self.entity.creator_name = creator_name
      self.entity.creator_id = self.creator_id
    end
    unless self.editor_id.blank?
      editor_name = Party.find(self.editor_id).display_name 
      self.editor_name = editor_name
      self.entity.editor_name = editor_name
      self.entity.editor_id = self.editor_id
    end 
  end
end
