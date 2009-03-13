#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Entity < ActiveRecord::Base
  belongs_to :account
  validates_presence_of :account_id
  
  include XlSuite::AccessRestrictions
  acts_as_taggable

  belongs_to :creator, :class_name => "Party", :foreign_key => :creator_id
  belongs_to :editor, :class_name => "Party", :foreign_key => :editor_id
  
  validates_presence_of :name, :classification
  validates_uniqueness_of :name, :scope => [:account_id, :classification]
  
  has_many :entity_addresses, :class_name => "AddressContactRoute", :as => :routable, :dependent => :destroy
  has_many :entity_email_addresses, :class_name => "EmailContactRoute", :as => :routable, :dependent => :destroy
  has_many :entity_links, :class_name => "LinkContactRoute", :as => :routable, :dependent => :destroy
  has_many :entity_phones, :class_name => "PhoneContactRoute", :as => :routable, :dependent => :destroy
  
  has_one :supplier, :dependent => :destroy
  
  before_save :update_creator_and_editor
  
  attr_accessor :addresses_changed, :email_addresses_changed, :links_changed, :phones_changed
  before_save :save_routes

  %w(addresses phones email_addresses links).each do |route|
    class_eval <<-EOF
      def #{route}=(attrs)
        #{route} = self.#{route}
        #{route}.attributes = attrs
        self.#{route}_changed = true
      end

      def #{route}
        self.entity_#{route} || self.build_entity_#{route}
      end
      
      def #{route}_changed?
        !self.#{route}_changed.blank?
      end
    EOF
  end

  def non_address_contact_routes
    (self.phones + self.links + self.email_addresses).sort_by(&:position)
  end

  protected
  
  # TODO do something about this later on
  def save_routes
    return if self.new_record?
    self.addresses.save! if self.addresses_changed?
    self.links.save! if self.links_changed?
    self.email_addresses.save! if self.email_addresses_changed?
    self.phones.save! if self.phones_changed?
  end
  
  def update_creator_and_editor
    self.creator_name = Party.find(self.creator_id).display_name unless self.creator_id.blank?
    self.editor_name = Party.find(self.editor_id).display_name unless self.editor_id.blank?
  end  
end
