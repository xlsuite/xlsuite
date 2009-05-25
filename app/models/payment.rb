#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Payment < ActiveRecord::Base
  attr_accessor :creator, :created_by, :created_by_id, :domain, :login_url, :reset_password_url, :subject_url
  
  belongs_to :account
  validates_presence_of :account_id
  
  belongs_to :payer, :class_name => "Party", :foreign_key => :payer_id
  validates_presence_of :payer_id

  has_many :payables, :order => "created_at", :dependent => :destroy, :extend => Extensions::Payables
  has_many :invoices, :through => :payables, :source => :subject, :source_type => "Invoice"
  has_many :orders, :through => :payables, :source => :subject, :source_type => "Order"

  acts_as_money :amount
  validates_presence_of :amount_cents
  validates_numericality_of :amount_cents

  acts_as_fulltext %w(payment_method amount description state created_at)

  ValidPaymentMethods = ['paypal', 'credit_card', 'check', 'cash', 'other'].freeze
  PaymentMethods = ValidPaymentMethods.map {|s| [s.capitalize, s.gsub(' ', '-')]}.freeze
  PaymentClasses = {'paypal' => 'PaypalPaymentHelper', 'credit_card' => 'CreditCardPaymentHelper',
                    'check' => 'CheckPaymentHelper', 'cash' => 'CashPaymentHelper',
                    'other' => 'OtherPaymentHelper'}

  validates_inclusion_of :payment_method, :in => ValidPaymentMethods

  has_many :transitions, :class_name => "PaymentTransition", :order => "created_at", :dependent => :destroy
  
  before_create :set_ever_failed
  after_create :create_payment_transition
  after_save :update_payable
  
  acts_as_state_machine :initial => :pending
  
  state :pending
  state :declined
  state :cancelled
  state :authorized
  state :paid, :after => :deliver_payment_confirmation
  
  event :decline_payment do
    transitions :from => :pending, :to => :declined
    transitions :from => :declined, :to => :declined
  end

  event :cancel_payment do
    transitions :from => :pending, :to => :cancelled
    transitions :from => :declined, :to => :cancelled
  end
  
  event :authorize_payment do
    transitions :from => :pending, :to => :authorized
    transitions :from => :authorized, :to => :authorized
    transitions :from => :declined, :to => :authorized
  end
  
  event :capture_payment do
    transitions :from => :pending, :to => :paid
    transitions :from => :authorized, :to => :paid
  end
  
  def to_liquid
    PaymentDrop.new(self)
  end

  def authorize(credit_card, options = {})
    transaction do
      authorization = PaymentTransition.authorize(amount, credit_card, options)
      self.transitions.push(authorization)
      if authorization.success?
        authorize!
      else
        decline!
      end
      authorization
    end
  end

  # Instantiates and returns a PaymentHelper.  The helpers are used to
  # implement the actual functionnality that Payment requires.
  def payment_helper
    raise ArgumentError, "No #payment_method defined on Payment:#{id}" if payment_method.blank?
    @payment_helper ||= PaymentClasses[payment_method].constantize.new
  end

  %w(start! receive! complete! cancel!).each do |method_name|
    self.class_eval <<-"end_eval"
      def #{method_name}(who, options={})
        result = []
        self.payables.each do |payable|
          result << payable.#{method_name}(who, options)
        end
        result
      end
    end_eval
  end
  
  # Describes this payment for Invoice#payments_as_text.
  def quick_description
    [payment_method, amount.format] * ' - '
  end

  def self.find_users_payments(user_ids, current_account)
    user_ids_arr = []
    user_ids.split(',').each{|id| user_ids_arr << id.to_i} unless user_ids.blank?
    current_account.payments.find(:all, :joins => 'INNER JOIN invoices ON invoices.id = payments.payable_id',
        :conditions => ["invoices.invoice_to_id IN (?) AND invoices.invoice_to_type = ?", user_ids_arr, "Party"])
  end
  
  protected
  def deliver_payment_confirmation
    begin      
      CustomerNotification.deliver_payment_received(
        :domain => self.domain,
        :payment => self,
        :login_url => self.login_url,
        :reset_password_url => self.reset_password_url,
        :subject_url => self.subject_url)
    rescue Net::SMTPSyntaxError
      # NOP
    end
  end
  
  def set_ever_failed
    self.ever_failed = false
    true
  end
  
  def update_payable
    return unless self.payables.count == 1
    payable = self.payables.first
    payable.amount = self.amount
    payable.save
  end
  
  def create_payment_transition
    self.transitions.create!(:to_state => "pending", :action => "create", :creator => self.creator || self.created_by, :account => self.account)
  end
end

class PaymentError < StandardError; end
class SpoofingAttemptError < PaymentError; end
class PaymentAlreadyProcessedError < PaymentError; end
