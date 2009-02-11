require File.dirname(__FILE__) + '/../test_helper'
require 'payment_controller'

# Re-raise errors caught by the controller.
class PaymentController; def rescue_action(e) raise e end; end

class PaymentReceptionAndNewAccountTest < Test::Unit::TestCase
  def setup
    @controller = PaymentController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @invoice = invoices(:johns_invoice)
    @customer = @invoice.customer
    @customer.login = nil
    @customer.email = 'johnny@test.com'
    @customer.save!

    @payment = @invoice.payments.build
    @payment.prepare!(:reason => '50% deposit', :amount => Money.new(12499))

    @owner = parties(:owner)
    addr = AddressContactRoute.new(:name => 'Office', :line1 => '123 Main St', :state => 'BC', :country => 'CAN')
    @owner.contact_routes << addr
    @owner.contact_routes << PhoneContactRoute.new(:name => 'Office', :number => '123-456-7890')

    @request.session[:payments] = [@payment.id]
    @request.session[XlSuite::AuthenticatedSystem::CURRENT_USER_ID] = @invoice.customer.id

    assert_not_nil @invoice.address
    post :thanks, :id => @payment.id
  end

  def test_renders_complete_invoice
    assert_select "#invoice_no", @invoice.no.to_s, @response.body
  end
end
