#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Estimate < ActiveRecord::Base
  include XlSuite::Invoicable

  acts_as_fulltext %w(care_of_name number date notes fst_name pst_name shipping_method status 
  created_by_name updated_by_name sent_at sent_by_name confirmed_by_name completed_by_name ship_to_type)

  validates_presence_of :date

  before_create :copy_ship_to_from_customer
  before_create :generate_random_uuid, :unless => :uuid?
  after_save :instantiate_email_contact_route

  belongs_to :payment_term
  validates_presence_of :payment_term_id
  before_validation :assign_default_payment_term

  belongs_to :referencable, :polymorphic => true

  serialize :info
  before_create {|e| e.info = Hash.new if e.info.nil?}

  def create_lines!(lines)
    lines["line"].each do |line|
      eline = self.lines.create!(line)
      unless line[:sku].blank? then
        product = self.account.products.find_by_sku(line[:sku])
        product = self.account.products.create!(:sku => line[:sku], :name => line[:description], :retail_price => line[:retail_price]) if product.blank?
        eline.update_attribute(:product_id, product.id)
      end
    end
  end

  # This is a workaround because it just won't write to the correct place!
  def uuid=(value)
    write_attribute(:uuid, value)
  end

  # This is a workaround because it just won't write to the correct place!
  def date=(value)
    write_attribute(:date, value)
  end

  def email=(value)
    case value
    when EmailContactRoute
      value.update_attribute(:routable, self)
      self.email(true)
    when String
      @email_address = value
    else
      raise "Invalid kind of value: expected EmailContactRoute or String, got #{value.class.name} (#{value.inspect})"
    end
  end

  def info
    read_attribute(:info) || write_attribute(:info, Hash.new)
  end

  def respond_to?(selector)
    selector.to_s =~ /(\w+)=$/ || super
  end

  def method_missing(selector, *args, &block)
    if selector.to_s =~ /(\w+)=$/ && !self.class.columns.map(&:name).include?($1) then
      return self.info[selector.to_s.chop] = args.first
    end

    if self.info.has_key?(selector.to_s) then
      return self.info[selector.to_s]
    end

    super
  end

  def to_liquid
    EstimateDrop.new(self)
  end

  def copy_ship_to_from_customer
    return if self.customer.blank?
    return if self.ship_to
    self.ship_to = self.customer.main_address.dup
  end
  
  def to_cart!
    attrs = self.attributes
    %w(completed_at completed_by_id completed_by_name confirmed_at confirmed_by_id confirmed_by_name info notes uuid 
       updated_by_id updated_by_name created_by_id created_by_name date number care_of_name reference_id reference_type 
       sent_at sent_by_id sent_by_name payment_term_id status created_at shipping_method id).each do |attr_name|
      attrs.delete(attr_name)
    end
  
    cart = self.account.carts.create!
    #TODO: before_filter copy_tax_info_over in invoicable overwrite the values that were setup initially
    cart.attributes = attrs
    cart.save!
    
    self.lines.each do |line|
      attributes = line.attributes
      ["estimate_id", "account_id", "comment"].each do |attribute|
        attributes.delete(attribute)
      end
      cart.lines.create!(attributes)
    end
    cart
  end

  class << self
    def find_next_number(account)
      year = Date.today.year
      maxno = account.estimates.maximum(:number, :conditions => ["LEFT(number, 4) = ?", year])
      maxno ? maxno.succ : sprintf("%04d%04d", year, 1)
    end
  end

  protected
  def instantiate_email_contact_route
    return if @email_address.blank?
    EmailContactRoute.create!(:address => @email_address, :routable => self, :account => self.account)
    self.email(true)
    @email_address = nil
    true
  end
end
