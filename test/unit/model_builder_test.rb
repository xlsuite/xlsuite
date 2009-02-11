require File.dirname(__FILE__) + "/../test_helper"

class ModelBuilderTest < Test::Unit::TestCase
  def test_create_redirect
    redirect = create_redirect!
    assert_valid redirect
    assert_kind_of Redirect, redirect
  end

  def test_create_order
    order = create_order!
    assert_valid order
    assert_kind_of Order, order
  end

  def test_params_for_order
    hash = params_for_order

    assert_include "invoice_to_id", hash
    assert_not_include "invoice_to", hash
    assert_kind_of String, hash["date"]
  end

  def test_create_invoice
    invoice = create_invoice!
    assert_valid invoice
    assert_kind_of Invoice, invoice
  end

  def test_params_for_invoice
    hash = params_for_invoice

    assert_include "invoice_to_id", hash
    assert_not_include "invoice_to", hash
    assert_kind_of String, hash["date"]
  end
end
