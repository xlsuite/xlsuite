require File.dirname(__FILE__) + '/../test_helper'
require 'orders_controller'

# Re-raise errors caught by the controller.
class OrdersController; def rescue_action(e) raise e end; end

class OrdersControllerTest < Test::Unit::TestCase
  def setup
    @controller = OrdersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @my_fish = products(:fish)
    @my_dog = products(:dog)
    @account = @my_fish.account
    @order = @account.orders.create!(:customer => parties(:bob), :date => Date.today)
    OrderLine.create!(:order => @order, :account => @account, :target_id => @my_fish.dom_id, :quantity => 2)
    OrderLine.create!(:order => @order, :account => @account, :target_id => @my_dog.dom_id, :quantity => 3)
  end

  context "An anonymous user" do
    should "be denied access to #create" do
      post :create, :order => {}
      assert_response :redirect
      assert_redirected_to new_session_path
    end

    should "be denied access to #update" do
      put :update, :id => @order.id, :order => {}
      assert_response :redirect
      assert_redirected_to new_session_path
    end
    
    context "trying to pay an order" do
      context "using paypal" do
        setup do
          post :pay, :uuid => @order.uuid, :payment_method => "paypal"
        end
        
        should "be redirected to paypal" do
          # should be redirected to PagesController#show since in test environment the Configuration for paypal_ipn_url is not setup
          assert_redirected_to :controller => "pages", :action => "show"
          assert_include "business=", @response.headers["Location"]
          assert_include "notify_url=", @response.headers["Location"]
        end
      end
    end
    
  end

  context "A logged in user without the :edit_orders permission" do
    setup do
      @bob = login_with_no_permissions!(:bob)
    end

    should "be denied access to #create" do
      post :create, :order => {}
      assert_template "shared/rescues/unauthorized"
    end

    should "be denied access to #update" do
      put :update, :id => @order.id, :order => {}
      assert_template "shared/rescues/unauthorized"
    end
  end

  context "A user with :edit_orders permission" do
    setup do
      @bob = login_with_permissions!(:bob, :edit_orders)
    end

    should_be_restful do |resource|
      resource.actions = %w(create update)
      resource.create.params = {:invoice_to_id => 1000001} # bob
    end
  end
end
