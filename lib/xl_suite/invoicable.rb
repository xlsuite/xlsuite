#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

require "geolocatable"

module XlSuite
  module Invoicable
    def self.included(base)
      base.before_create :assign_next_number
      base.before_save :copy_tax_info_over, :if => :new_record?
      base.attr_protected :number

      base.belongs_to :account
      base.validates_presence_of :account_id
      base.before_validation :set_invoicable_account
      
      base.belongs_to :domain

      base.belongs_to :invoice_to, :polymorphic => true
      base.validates_presence_of :invoice_to_id, :if => :customer_required?

      base.has_one :ship_to, :as => :routable, :class_name => "AddressContactRoute"
      base.has_one :phone, :as => :routable, :class_name => "PhoneContactRoute"
      base.has_one :email, :as => :routable, :class_name => "EmailContactRoute"

      base.has_many :payables, :as => :subject, :order => "payables.created_at", :extend => Extensions::Payables
      base.has_many :payments, :through => :payables, :extend => Extensions::Payments

      base.has_many :lines, :class_name => base.name + "Line", :order => "position", :extend => Extensions::Lines, :dependent => :destroy

      base.belongs_to :care_of, :class_name => "Party", :foreign_key => :care_of_id

      base.acts_as_money :shipping_fee, :transport_fee, :equipment_fee

      base.acts_as_money :downpayment_amount

      column_names = base.columns.map(&:name) rescue []
      %w(created updated sent confirmed paid completed voided).each do |attr|
        next unless column_names.include?("#{attr}_by_id")
        base.belongs_to "#{attr}_by".to_sym, :class_name => "Party", :foreign_key => "#{attr}_by_id"
        base.before_save {|r| r.send("#{attr}_by_name=", r.send("#{attr}_by").if_not_nil {|p| p.name.to_s})}
      end

      base.before_save :set_paid_in_full
      base.before_save :copy_name_from_editors
      base.before_create :set_tax_flags

      base.acts_as_taggable
      base.acts_as_geolocatable
    end

    def total_payments(currency=Money.default_currency)
      self.payables.map(&:amount).sum(Money.zero(currency))
    end

    def make_payment!(payment_method, who=self.invoice_to)
      raise XlSuite::PaymentSystem::HasBeenPaidInFull if self.paid_in_full?
      payment = self.account.payments.create!(:payment_method => payment_method, :payer => who, :description => "Payment for #{self.class.name} #{self.id}", :amount => self.total_amount)
      payable = self.account.payables.create!(:subject => self, :payment => payment, :amount => payment.amount)
      payment      
    end

    def set_invoicable_account
      return unless self.customer_required?
      self.account = self.invoice_to.if_not_nil {|customer| customer.account} if self.account.blank?
    end
    protected :set_invoicable_account

    def customer_required?
      true
    end
    protected :customer_required?

    def assign_next_number
      self.number = self.class.find_next_number(self.account)
    end
    protected :assign_next_number

    def assign_default_payment_term
      return if self.payment_term
      self.payment_term = self.account.payment_terms.parse(self.account.get_config(:default_payment_term) || "n/0")
    end
    protected :assign_default_payment_term

    def customer
      self.invoice_to
    end

    def customer=(value)
      self.invoice_to = value
    end

    def copy_tax_info_over
      %w(fst_rate pst_rate).each do |attr|
        next if self.attribute_present?(attr)
        rate = self.account.get_config(attr)
        self.send("#{attr}=", rate)
      end

      %w( fst_active fst_name
          pst_active pst_name
          apply_fst_on_products apply_pst_on_products
          apply_fst_on_labor apply_pst_on_labor).each do |attr|
        self.send("#{attr}=", self.account.get_config(attr))
      end
    end
    protected :copy_tax_info_over

    def void!(admin, now=Time.now.utc)
      self.class.transaction do
        self.voided_by = admin
        self.voided_at = now
        self.save!

        self.payables(true).each {|p| p.void!(admin, now)}
      end
    end

    def void?
      return false unless self.has_attribute?("voided_at")
      !!self.voided_at
    end
    alias_method :voided?, :void?

    def paid?
      self.balance.zero?
    end
    alias_method :paid_in_full?, :paid?

    def fees_amount(currency=Money.default_currency)
      shipping_fee + transport_fee + equipment_fee
    end

    def fees_fst_amount(currency=Money.default_currency)
      fees_amount(currency) * fst_rate / 100.0
    end

    def fees_pst_amount(currency=Money.default_currency)
      fees_amount(currency) * pst_rate / 100.0
    end

    def subtotal_and_fees_amount(currency=Money.default_currency)
      subtotal_amount(currency) + fees_amount(currency)
    end

    def products_amount(currency=Money.default_currency)
      self.lines.products.map(&:extension_price).compact.reject(&:zero?).sum(Money.zero(currency))
    end

    def labor_amount(currency=Money.default_currency)
      self.lines.labor.map(&:extension_price).compact.reject(&:zero?).sum(Money.zero(currency))
    end

    def subtotal_amount(currency=Money.default_currency)
      [self.products_amount, self.labor_amount].compact.reject(&:zero?).sum(Money.zero(currency))
    end

    def products_fst_amount(currency=Money.default_currency)
      return Money.zero(currency) unless fst_active
      return Money.zero(currency) unless apply_fst_on_products
      self.products_amount(currency) * fst_rate / 100.0
    end

    def products_pst_amount(currency=Money.default_currency)
      return Money.zero(currency) unless pst_active
      return Money.zero(currency) unless apply_pst_on_products
      self.products_amount(currency) * pst_rate / 100.0
    end

    def labor_fst_amount(currency=Money.default_currency)
      return Money.zero(currency) unless fst_active
      return Money.zero(currency) unless apply_fst_on_labor
      self.labor_amount(currency) * fst_rate / 100.0
    end

    def labor_pst_amount(currency=Money.default_currency)
      return Money.zero(currency) unless pst_active
      return Money.zero(currency) unless apply_pst_on_labor
      self.labor_amount(currency) * pst_rate / 100.0
    end

    def fst_amount(currency=Money.default_currency)
      fst_subtotal_amount(currency) * fst_rate / 100.0
    end

    def pst_amount(currency=Money.default_currency)
      pst_subtotal_amount(currency) * pst_rate / 100.0
    end

    def total_amount(currency=Money.default_currency)
      [subtotal_amount(currency), fst_amount(currency), pst_amount(currency), fees_amount(currency)].reject(&:zero?).sum(Money.zero(currency))
    end

    def fst_subtotal_amount(currency=Money.default_currency)
      subtotal = Money.zero(currency)
      subtotal += products_amount(currency) if fst_active? && apply_fst_on_products?
      subtotal += labor_amount(currency) if fst_active? && apply_fst_on_labor?
      subtotal += fees_amount(currency) if fst_active? && apply_fst_on_products?
      subtotal
    end

    def pst_subtotal_amount(currency=Money.default_currency)
      subtotal = Money.zero(currency)
      subtotal += products_amount(currency) if pst_active? && apply_pst_on_products?
      subtotal += labor_amount(currency) if pst_active? && apply_pst_on_labor?
      subtotal += fees_amount(currency) if pst_active? && apply_pst_on_products?
      subtotal
    end

    def balance(currency=Money.default_currency)
      self.total_amount(currency) - self.payables.total_completed(currency)
    end

    def copy_name_from_editors
      %w(created updated sent confirmed completed voided paid).each do |attr|
        next unless self.respond_to?("#{attr}_at") && self.respond_to?("#{attr}_by")

        if self.send("#{attr}_at") then
          if party = self.send("#{attr}_by") then
            if name = party.name then
              self.send("#{attr}_by_name=", name.to_forward_s)
            else
              self.send("#{attr}_by_name=", nil)
            end
          else
            self.send("#{attr}_by_name=", nil)
          end
        else
          self.send("#{attr}_by=", nil)
          self.send("#{attr}_by_name=", nil)
        end
      end
    end
    protected :copy_name_from_editors

    def set_tax_flags
      self.fst_active = false
      self.pst_active = false
      return unless self.ship_to && self.account

      t_address = self.ship_to
      s_address = self.account.owner.main_address
      return if s_address.new_record? || t_address.new_record?
      if t_address.country == s_address.country
        self.fst_active = true if self.account.get_config("fst_active")

        self.pst_active = true if((t_address.state == s_address.state) && self.account.get_config("pst_active"))
      end
    end
    protected :set_tax_flags

    def set_paid_in_full
      return unless self.respond_to?(:paid_in_full=)
      if self.balance.zero? && !self.total_amount.zero?
        self.paid_in_full = true
        self.paid_in_full_at = Time.now unless self.paid_in_full_at
      else
        self.paid_in_full = false
        self.paid_in_full_at = nil
      end
        
      #Don't return false if balance is not zero
      true
    end
    protected :set_paid_in_full
  end
end
