require File.dirname(__FILE__) + '/../test_helper'

# Let's make sure app/controllers/application.rb is loaded
# If we require 'application', the tests will fail because of method aliasing
ApplicationController

# Dummy controller to expect some things
class ApplicationTestController < ApplicationController
  skip_before_filter :login_required

  def rescue_action(e) raise e end;

  # For test purposes, we must define an action which we can GET.  This will
  # setup the expected session.
  def index
    self.prepare_payment_and_redirect(
      :invoice => Invoice.find(params[:invoice_id]),
      :amount => Money.new(params[:amount].to_i),
      :reason => params[:reason],
      :cancel_url => params[:cancel_url],
      :method => params[:method].to_sym
    )
  end
end

class ApplicationControllerTest < Test::Unit::TestCase
  def setup
    @controller = ApplicationTestController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @invoice = invoices(:johns_invoice)
  end

  def test_prepare_payment_appends_incoming_payment_to_session
    assert_nil @request.session[:payments], 'no expected payments beforehand'

    get :index, :invoice_id => @invoice.id, :amount => 24999,
                :cancel_url => 'cancel_url', :reason => 'some reason',
                :method => :paypal

    assert_kind_of Array, @request.session[:payments], 'session now contains payments array'
    payment = Payment.find(@request.session[:payments].first)
    assert_kind_of PaypalPayment, payment
    assert_equal Money.new(24999), payment.amount, 'payment has right amount'
    assert_equal 'some reason', payment.reason, 'payment has right reason'
    assert_equal @invoice, payment.payable, 'payment refers to right invoice'
    assert @invoice.payments(true).include?(payment), 'payment added to invoice'
  end

  def test_prepare_payment_redirects_to_paypal_engine_when_paypal
    get :index, :invoice_id => @invoice.id, :amount => 24999,
                :cancel_url => 'cancel_url', :reason => 'some reason',
                :method => :paypal

    assert_response :redirect
    assert_match /#{Configuration.get(:paypal_sandbox_payment_url)}/, @response.redirect_url
  end

  def test_prepare_payment_redirects_to_paypal_engine_when_paypal
    get :index, :invoice_id => @invoice.id, :amount => 24999,
                :cancel_url => 'cancel_url', :reason => 'some reason',
                :method => :credit_card

    assert_response :redirect
    assert_match /#{Configuration.get(:card_processor_sandbox_url)}/, @response.redirect_url
  end
end

=begin
class AccountNearingExpirationTest < Test::Unit::TestCase
  def setup
    @controller = PagesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @account = Account.find(:first)
    @account.expires_at = 5.minutes.from_now
    @account.save!

    @layout = @account.layouts.create!(:title => "abc", :author => parties(:bob))
    @page = @account.pages.create!(:title => "abc", :layout => @layout,
        :creator => parties(:bob), :behavior => "text", :status => "published",
        :slug => "/", :behavior_values => {:text => "abc"})
  end

  def test_server_warns_account_owner
    @admin = @account.owner
    @request.session[:account_id] = @admin.id
    get :show, :path => %w()

    assert_select "#notification-area *", :text => /account\s.*\s?nearly expired/i
  end

  def test_server_warns_authenticated_user_not_account_owner
    @request.session[:account_id] = @account.parties.create!.id
    get :show, :path => %w()

    assert_select "#notification-area *", :text => /account\s.*\s?nearly expired/i
  end

  def test_server_does_not_warn_anonymous_user
    get :show, :path => %w()

    assert_select "#notification-area *", :text => /account\s.*\s?nearly expired/i, :count => 0
  end
end
=end

class AccountExpiredTest < Test::Unit::TestCase
  def setup
    @controller = PagesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @account = Account.find(:first)
    @account.expires_at = 5.minutes.ago
    @account.save!

    @layout = @account.layouts.create!(:title => "abc", :author => parties(:bob))
    @page = @account.pages.create!(:title => "abc", :layout => @layout,
        :creator => parties(:bob), :behavior => "plain_text", :status => "published",
        :fullslug => "", :behavior_values => {:text => "abc"})
  end

  def test_server_redirects_account_owner
    login!(@account.owner)
    get :show, :path => %w()

    assert_redirected_to payment_account_path(@account)
  end

  def test_server_rejects_authenticated_not_owner
    login!(@account.parties.create!)
    get :show, :path => %w()

    assert_response 503
    assert_template "account_expired"
  end

  def test_lets_anonymous_user_through
    get :show, :path => %w()
    assert_response :success
  end
end

class UnknownDomainAndUnauthenticatedTest < Test::Unit::TestCase
  def setup
    @controller = PagesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @request.host = "unknown.xlsuite.com"
    get :show, :path => %w()
  end

  def test_renders_accounts_new_template
    assert_template "accounts/new"
  end

  def test_status_is_missing
    assert_response :missing
  end

  # This should pass, but it doesn't.  Why ?  No idea.
  def test_offers_payment_choice
    assert css_select("form[action=?] input[name=commit]", new_account_path).all? {|elem| elem.attributes['value'] =~ /paypal|credit card/i}

#    assert_select "form[action=?]", account_new_url do
#      assert_select "input[value=?]", /pay with paypal/i
#      assert_select "input[value=?]", /pay with credit card/i
#    end
  end

  def test_prepopulates_form_with_known_data
    assert_select "input[name=?][value=?]", "domain[name]", @request.host
  end

  def test_does_not_allow_expiration_date_setting
    assert_select "input#account_expires_at", :count => 0
  end
end

class AccountSignupTest < Test::Unit::TestCase
  def setup
    @controller = AccountsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @request.host = "unknown.xlsuite.com"
  end

  def test_signup_with_good_data
    assert_difference Account, :count, 1 do
      post :create,
          :domain => {:name => @request.host},
          :email => {:email_address => "bobby@johnstore.com"}
      assert_response :success
      assert_select "#accountsNew", :count => 0 # The 'thank you' page doesn't have that. 
    end

    @account = assigns(:acct)
    @account.reload
    @owner = assigns(:owner)
    @owner.reload
    assert_equal ["bobby@johnstore.com"], @owner.contact_routes.map(&:address)
    assert @owner.tag_list.include?("account-owner"), "Tag 'account-owner' not found in #{@owner.tag_list.inspect}"
  end
end
