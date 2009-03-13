#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

require "xl_suite/invoicable"

class Cart < ActiveRecord::Base
  attr_accessor :number

  include XlSuite::Invoicable
  
  before_save :update_invoice_to
  
  %w(sent confirmed paid completed voided).each do |attr|
    self.class_eval <<-"end_eval"
      def #{attr}_by_name=(object)
      end
    end_eval
  end
  
  %w(ship_to email phone).each do |method|
    self.class_eval <<-"end_eval"
      def #{method}_attrs=(params)
        cart_#{method} = self.#{method}
        if params.kind_of?(Hash)
          if cart_#{method}
            if cart_#{method}.new_record?
              cart_#{method}.attributes = params
              cart_#{method}.account = self.account
              cart_#{method}.save unless self.new_record?
            else
              cart_#{method}.update_attributes(params)
            end
          else
            cart_#{method} = self.build_#{method}(params)
            cart_#{method}.account = self.account
            cart_#{method}.save unless self.new_record?
          end
        end
      end
    end_eval
  end
  
  def invoice_to_attrs=(params)
    cart_invoice_to = self.invoice_to
    if params.kind_of?(Hash)
      if params[:email] && !params[:email][:email_address].blank?
        party = Party.find_by_account_and_email_address(self.account, params.delete(:email)[:email_address])
      end
      if party
        party.update_attributes!(params)
        self.invoice_to = party
      elsif cart_invoice_to
        if cart_invoice_to.new_record?
          cart_invoice_to.attributes = params
          cart_invoice_to.account = self.account
        end
      else
        self.invoice_to = self.account.parties.build(params)
      end
    end
  end
  
  def add_routes_to_invoice_to!
    return unless self.invoice_to && self.invoice_to.kind_of?(Party)
    party = self.invoice_to

    cart_email = self.email
    if cart_email
      party.email_addresses.create(:name => cart_email.name, :email_address => cart_email.email_address, :account => self.account)
    end

    cart_ship_to = self.ship_to
    if cart_ship_to
      party.addresses.create(cart_ship_to.dup.attributes.merge(:account => self.account))
    end

    cart_phone = self.phone
    if cart_phone
      party.phones.create(:name => cart_phone.name, :number => cart_phone.number, :account => self.account)
    end    
  end
    
  def subtotal
    self.lines.map(&:total).sum
  end
  
  def self.find_next_number(account=nil)
    nil
  end
  
  def to_liquid
    CartDrop.new(self)
  end
  
  def add_product(params)
    returning(self.lines.find_or_initialize_by_product_id(params[:product_id])) do |line|
      line.cart = self
      if line.new_record? 
        line.quantity = params[:quantity].blank? ? 1 : params[:quantity]
      else
        line.quantity += params[:quantity].to_i
      end
      line.save!
    end
  end
  
  def to_order!
    raise ArgumentError, "Please assign invoice_to to the Cart before calling Cart\#to_order!" if self.invoice_to.blank?
    self.save! if self.new_record?

    order = self.account.orders.build
    order.attributes = self.attributes
    order.date = Time.now
    if self.ship_to
      order.ship_to = self.ship_to.dup
      order.ship_to.account = self.account
    end
    if self.phone
      order.phone = self.phone.dup
      order.phone.account = self.account
    end
    if self.email
      order.email = self.email.dup
      order.email.account = self.account
    end
    
    order.shipping_fee = self.shipping_amount
    
    order.save!
    self.lines.each do |line|
      attributes = line.attributes
      ["cart_id", "type"].each do |attribute|
        attributes.delete(attribute)
      end
      order.lines.create!(attributes)
    end
    order.reload.send_order_email!
    order
  end
  
  def shipping_amount
    country = self.ship_to ? self.ship_to.country : ""
    state = self.ship_to ? self.ship_to.state : ""
    self.account.destinations.shipping_cost_for_country_and_state(country, state)
  end
  
  protected
  
  def update_invoice_to
    return unless self.email && !self.email.email_address.blank? && self.account
    party = Party.find_by_account_and_email_address(self.account, self.email.email_address)
    return unless party
    old_invoice_to = self.invoice_to
    if old_invoice_to && !old_invoice_to.name.to_s.blank? 
      party.full_name = old_invoice_to.name.to_s
      party.save
    end
    self.invoice_to = party
  end
  
  def customer_required?
    false
  end    
end
