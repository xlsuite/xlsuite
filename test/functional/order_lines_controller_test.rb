require File.dirname(__FILE__) + '/../test_helper'
require 'order_lines_controller'

# Re-raise errors caught by the controller.
class OrderLinesController; def rescue_action(e) raise e end; end

class OrderLinesControllerTest < Test::Unit::TestCase
  def setup
    @controller = OrderLinesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @account = Account.find(1)
    @order = Order.create!(:account => @account, :customer => parties(:bob), :date => Time.now())
    @order.lines << @order_line = OrderLine.new(:description => "This is a description")
    assert_valid @order_line
  end

  context "An anonymous user" do
    should "be denied POST #create access" do
      post :create, :order_id => @order.id, :order_line => {}
      assert_redirected_to new_session_path
    end

    should "be denied PUT #update access" do
      put :update, :order_id => @order.id, :id => @order_line.id, :order_line => {}
      assert_redirected_to new_session_path
    end

    should "be denied POST #destroy_collection access" do
      post :destroy_collection, :order_id => @order.id, :ids => @order_line.id, :order_line => {}
      assert_redirected_to new_session_path
    end
  end

  context "A logged in user without the :edit_orders permission" do
    setup do
      @bob = login_with_no_permissions!(:bob)
    end

    should "be denied POST #create access" do
      post :create, :order_id => @order.id, :order_line => {}
      assert_template "shared/rescues/unauthorized"
    end

    should "be denied PUT #update access" do
      put :update, :order_id => @order.id, :id => @order_line.id, :order_line => {}
      assert_template "shared/rescues/unauthorized"
    end

    should "be denied POST #destroy_collection access" do
      post :destroy_collection, :order_id => @order.id, :ids => @order_line.id, :order_line => {}
      assert_template "shared/rescues/unauthorized"
    end
  end

  context "A logged in user with the :edit_orders permission" do
    setup do
      @bob = login_with_permissions!(:bob, :edit_orders)
    end

    should "create an OrderLine" do
      assert_difference @order.lines, :count, +1 do
        post :create, :order_id => @order.id, :order_line => {:description => "Killimanjaro"}
      end
    end

  end
end
