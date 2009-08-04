#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ContactRoute < ActiveRecord::Base
  abstract_class = true

  acts_as_list :scope => 'routable_type = \"#{routable_type}\" AND routable_id = #{routable_id}'
  belongs_to :routable, :polymorphic => true

  attr_accessor :skip_account
  
  belongs_to :account
  validates_presence_of :account_id, :unless => :skip_account

  before_validation :set_name
  validates_presence_of :name, :routable_type, :routable_id
  validates_length_of :name, :within => (1 .. 200)

  before_validation :set_account
  
  before_create :generate_random_uuid, :unless => :skip_account

  %w(email address phone link).each do |attr|
    define_method("#{attr}_route?") do
      self.class.name.underscore.split("_").first == attr
    end
  end

  def name=(value)
    value = (value || "").mb_chars.gsub(/\s{2,}/, ' ').titleize
    write_attribute(:name, value.blank? || value.empty? ? nil : value)
  end

  def choices(base_choices=nil)
    (%W(#{self.name} Main) + base_choices + %w(Other...)).reject(&:blank?).uniq
  end

  def copy_to(target)
    #RAILS_DEFAULT_LOGGER.debug("I am in copy_to")
    self.class.name.constantize.content_columns.map(&:name).each do |column|
      next if column =~ /(position|routable_type)/i
      target.send("#{column}=", self.send(column))
    end
    #RAILS_DEFAULT_LOGGER.debug("I am in copy_to before save!")
    target.save!
    #RAILS_DEFAULT_LOGGER.debug("I am in copy_to almost done!")
  end
  
  def main_identifier
    ""
  end
  
  def dup
    self.class.new(:name => self.name,
        :line1 => self.line1, :line2 => self.line2, :line3 => self.line3,
        :city => self.city, :state => self.state, :country => self.country, 
        :zip => self.zip, 
        :email_address => self.email_address,
        :number => self.number,
        :url => self.url)
  end
  
  protected
  def set_account
    if self.routable && self.routable.respond_to?(:account)
      self.account = self.routable.account
    end 
  end
  
  def set_name
    self.name = "Main" if self.name.blank? || self.name.empty?
  end
end
