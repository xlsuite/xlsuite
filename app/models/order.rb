#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Order < ActiveRecord::Base
  include XlSuite::Invoicable
  include XlSuite::AffiliateAccountHelper

  acts_as_reportable
  acts_as_fulltext %w(care_of_name number date notes fst_name pst_name shipping_method status invoiced_to_name
      created_by_name updated_by_name sent_at sent_by_name confirmed_by_name completed_by_name voided_by_name ship_to_type)
  
  has_many :invoices, :dependent => :nullify
  
  before_create :copy_ship_to_from_customer, :generate_random_uuid
  before_save :truncate_tax_names

  belongs_to :payment_term
  validates_presence_of :payment_term_id
  before_validation :assign_default_payment_term
  before_validation :set_date_if_blank
  before_validation :set_status_if_blank
  
  belongs_to :referencable, :polymorphic => true
  
  before_save :set_completed_if_paid
  after_save :update_party_expiring_items
  
  def to_liquid
    OrderDrop.new(self)
  end
  
  def send_order_email!
    recipient = self.account.get_config(:notify_order_email)
    return if recipient.blank? || self.paid?
    AdminMailer.deliver_new_order(:order => self, :recipients => recipient)    
  end

  def to_new_invoice
    order_attrs = self.attributes
    %w(confirmed_by_name confirmed_at confirmed_by_id completed_at completed_by_id completed_by_name 
      uuid reference_type reference_id).each do |attr_name|
      order_attrs.delete(attr_name)
    end
    t_invoice = self.account.invoices.build(order_attrs)
    t_invoice.order = self
    self.lines.each do |ol|
      i_line_quantity = ol.quantity - ol.quantity_invoiced
      if i_line_quantity != 0
        ol_attrs = ol.attributes
        ol_attrs.delete("order_id")
        ol_attrs.delete("quantity_shipped")
        ol_attrs.delete("quantity_invoiced")
        ol_attrs.merge("quantity" => i_line_quantity)
        i_line = t_invoice.lines.build(ol_attrs)
        i_line.invoice = t_invoice
      end
    end
    t_invoice
  end
  
  def generate_new_invoice!
    new_invoice = self.to_new_invoice
    #raise XlSuite::PaymentSystem::HasNotBeenModified, "New invoice cannot be generated, there is no change on this order" if new_invoice.balance.zero?
    new_invoice.save!
    new_invoice
  end
  
  def subscription?
    self.lines.each do |line|
      next unless line.product
      return true if line.product.pay_period
    end
    false
  end
  
  def subscription_product
    self.lines.each do |line|
      next unless line.product
      return line.product if line.product.pay_period
    end
    nil
  end
  
  def subscription_next_renewal_at(base=Time.now.utc)
    subscription_product = self.subscription_product
    return nil unless subscription_product
    next_renewal_at = Time.now.utc + subscription_product.pay_period_length.send(subscription_product.pay_period_unit).to_i
    if subscription_product.free_period_unit && subscription_product.free_period_length
      next_renewal_at += subscription_product.free_period_length.send(subscription_product.free_period_unit).to_i
    end
    next_renewal_at
  end
  
  def invoiced_to_name
    self.invoice_to ? (self.invoice_to.full_name.blank? ? self.invoice_to.display_name : self.invoice_to.full_name) : ""
  end

  protected
  def process_affiliate_account(affiliate_account)
    item = AffiliateAccountItem.new
    item.target = self
    item.affiliate_account = affiliate_account
    item.account_id = self.account_id
    item.domain_id = self.domain_id
    item.save!
    item_line = nil
    product = nil
    self.lines.each do |o_line|
      next unless o_line.product
      product = o_line.product
      product_affiliate = AffiliateSetupLine.first(:conditions => {:target_id => product.id, :target_type => product.class.name, :level => item.level})
      next unless product_affiliate
      item_line = AffiliateAccountItemLine.new
      item_line.affiliate_account_item = item
      item_line.target = product
      item_line.commission_percentage = product_affiliate.percentage
      item_line.status = self.status
      item_line.price = o_line.retail_price
      item_line.quantity = o_line.quantity
      item_line.commission_amount = o_line.extension_price * (product_affiliate.percentage.to_f / 100)
      item_line.level = item.level
      if product.pay_period
        item_line.subscription_period = product.pay_period
        start_time = Time.now.utc
        start_time += product.free_period.to_i if product.free_period
        item_line.subscription_started_at = start_time
      end
      item_line.save!
    end
    item.reload
    item.destroy if item.lines.count == 0
    true
  end
  
  def copy_ship_to_from_customer
    return unless self.customer || self.ship_to
    self.ship_to = self.customer.main_address.dup unless self.ship_to
  end
  
  def truncate_tax_names
    self.fst_name = self.fst_name.slice(0, 8) if self.fst_name
    self.pst_name = self.pst_name.slice(0, 8) if self.pst_name
  end
  
  def set_completed_if_paid
    @_old_status = self.class.find(self.id).status unless self.new_record?
    self.status = "Completed" if self.paid_in_full
  end
  
  def update_party_expiring_items
    return nil unless self.invoice_to && self.invoice_to.kind_of?(Party)
    out = []
    if self.status =~ /complete/i && @_old_status != self.status
      self.lines.each do |line|
        out += line.attach_expiring_items_to!(self.invoice_to, {:updated_by => self, :created_by => self})
      end
    end
    out.compact
  end
  
  def set_date_if_blank
    return true unless self.date.blank?
    self.date = Date.today
    true
  end
  
  def set_status_if_blank
    return true unless self.status.blank?
    self.status = "New"
    true
  end
  
  class << self
    def find_next_number(account)
      year = Date.today.year
      maxno = account.orders.maximum(:number, :conditions => ["LEFT(number, 4) = ?", year])
      maxno ? maxno.succ : sprintf("%04d%04d", year, 1)
    end
  end
end
