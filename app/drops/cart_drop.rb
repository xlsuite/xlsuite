#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class CartDrop < Liquid::Drop
  attr_reader :cart
  delegate :id, :invoice_to, :ship_to, :care_of, :care_of_name, :number, :date,
    :notes, :fst_active, :fst_rate, :fst_name, :pst_active, :pst_rate,
    :pst_name, :shipping_method, :status, :created_at, :updated_at,
    :sent_at, :confirmed_at, :completed_at, :phone, :email, :payments,
    :lines, :products_amount, :labor_amount, :subtotal_amount,
    :products_fst_amount, :products_pst_amount, :labor_fst_amount,
    :labor_pst_amount, :fst_amount, :pst_amount, :total_amount,
    :balance, :uuid, :shipping_fee, :transport_fee, :equipment_fee, :fees_amount,
    :fees_pst_amount, :fees_fst_amount, :subtotal_and_fees_amount, :downpayment_amount, :to => :cart

  def initialize(cart)
    @cart = cart
  end

  alias_method :address, :ship_to
  alias_method :subtotal, :subtotal_amount
  alias_method :total, :total_amount
  alias_method :shipping_amount, :shipping_fee
end
