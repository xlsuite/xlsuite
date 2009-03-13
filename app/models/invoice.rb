#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Invoice < ActiveRecord::Base
  include XlSuite::Invoicable

  acts_as_reportable 

  belongs_to :order
  validates_presence_of :order_id, :if => Proc.new{|e| e.new_record?}

  belongs_to :payment_term
  validates_presence_of :payment_term_id
  before_validation :assign_default_payment_term

  validates_presence_of :date

  before_create :generate_random_uuid

  acts_as_fulltext %w(number customer_name iso_date),
      %w(date customer_email_addresses address_as_text line_items_as_text payments_as_text)
      
  after_create :update_order_lines_quantity_invoiced!

  def to_liquid
    InvoiceDrop.new(self)
  end
  
  def to_pdf
    PdfGenerator.new(self).build
  end

  def void_with_payments!(who, time=Time.now.utc)
    self.class.transaction do
      void_without_payments!(who, time)
      self.decrease_order_lines_quantity_invoiced!
      self.payables.each {|payable| payable.void!(who, time)}
    end
  end

  alias_method_chain :void!, :payments

  def completed_payments_amount(currency=Money.default_currency)
    (self.payments.completed + self.order.payments.completed).map(&:amount).sum(Money.zero(currency))
  end

  def send_to_customer!(options={})
    options.assert_valid_keys(:template, :invoice_url, :sender)

    email_template = options[:template]
    invoice_url = options[:invoice_url]
    sender = options[:sender]
    raise ArgumentError, "Missing template" if email_template.blank?
    raise ArgumentError, "Missing invoice_url" if invoice_url.blank?
    raise ArgumentError, "Missing sender" if sender.blank?

    extras = {'invoice_total' => self.total,
              'unpaid_balance' => self.balance,
              'invoice_pay_url' => invoice_url}

    self.class.transaction do
      self.customer.tag('waiting-for-payment') unless self.customer.tag_list.include?('waiting-for-payment')

      returning email_template.build_email do |email|
        email.sender = sender
        email.inline_attachments = true
        email.tos.build(:party => self.customer, :extras => extras)
        email.bccs.build(:party => sender, :extras => extras)
        email.about = self
        email.save!

        email.attachments << Attachment.new(:temp_data => self.to_pdf,
            :content_type => 'application/pdf', :owner => self.customer,
            :title => "invoice-#{self.number}", :filename => "invoice-#{self.number}.pdf")

        email.release!
      end
    end
  end

  def self.next_invoice_no
    top = Invoice.maximum(:number, :conditions => ['number LIKE ?', sprintf('%04d%%', Date.today.year)])
    return sprintf('%04d%04d', Date.today.year, 1) unless top
    top.succ
  end

  def balance(currency=Money.default_currency)
=begin
    previous_invoice = if self.new_record?
        self.order.invoices.find(:first, :order => "id DESC")
      else
        self.order.invoices.find(:first, :conditions => ["id < ?", self.id], :order => "id DESC")
      end
    previous_invoice_balance = Money.new(0)
    previous_invoice_balance = previous_invoice.balance if previous_invoice
    RAILS_DEFAULT_LOGGER.debug("^^^previos invoice balance = #{previous_invoice_balance.inspect}")
    # TODO: we are screwed on this the "self.order.payables.total_completed(currency)" need a way to say
    # retrieve payables that have not been invoiced
    self.total_amount(currency) + previous_invoice_balance - self.payables.total_completed(currency) - self.order.payables.total_completed(currency)
=end
    if self.order then
      self.order.total_amount(currency) - self.order.payables.total_completed(currency)
    else
      self.total_amount(currency) - self.total_payments(currency)
    end
  end

  protected
  class << self
    def find_next_number(account)
      year = Date.today.year
      maxno = account.invoices.maximum(:number, :conditions => ["LEFT(number, 4) = ?", year])
      maxno ? maxno.succ : sprintf("%04d%04d", year, 1)
    end
  end

  def iso_date
    self.date.to_s(:iso)
  end

  def line_items_as_text
    self.lines.map(&:description)
  end

  def payments_as_text
    self.payments.map(&:quick_description)
  end

  def customer_name
    return unless self.customer
    self.customer.display_name
  end
  
  def customer_email_addresses
    return unless self.customer
    self.customer.email_addresses.map(&:address)
  end

  def address_as_text
  end
  
  def update_order_lines_quantity_invoiced!
    raise "Invoice order must exist on create" unless self.order
    self.lines.each do |il|
      self.order.lines.each do |ol| 
        if ol.product_id == il.product_id && ol.description == il.description && ol.sku == il.sku && ol.comment == il.comment
          ol.quantity_invoiced += il.quantity
          ol.save!
        end
      end
    end
  end
  
  def decrease_order_lines_quantity_invoiced!
    raise "Invoice must have an order" unless self.order
    self.lines.each do |il|
      self.order.lines.each do |ol|
        if ol.product_id == il.product_id && ol.description == il.description && ol.sku == il.sku && ol.comment == il.comment
          ol.quantity_invoiced -= il.quantity
          ol.save!
        end
      end
    end
  end
end
