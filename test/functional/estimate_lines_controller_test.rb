require File.dirname(__FILE__) + '/../test_helper'
require 'estimate_lines_controller'

# Re-raise errors caught by the controller.
class EstimateLinesController; def rescue_action(e) raise e end; end

class EstimateLinesControllerTest < Test::Unit::TestCase
  def setup
    @controller = EstimateLinesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @account = Account.find(1)
    @estimate = Estimate.create!(:account => @account, :customer => parties(:bob), :date => Time.now())
    @estimate.lines << @estimate_line = EstimateLine.new(:description => "This is a description")
    assert_valid @estimate_line
  end

  context "An anonymous user" do
    should "be denied POST #create access" do
      post :create, :estimate_id => @estimate.id, :estimate_line => {}
      assert_redirected_to new_session_path
    end

    should "be denied PUT #update access" do
      put :update, :estimate_id => @estimate.id, :id => @estimate_line.id, :estimate_line => {}
      assert_redirected_to new_session_path
    end

    should "be denied POST #destroy_collection access" do
      post :destroy_collection, :estimate_id => @estimate.id, :ids => @estimate_line.id, :estimate_line => {}
      assert_redirected_to new_session_path
    end
  end

  context "A logged in user without the :edit_estimates permission" do
    setup do
      @bob = login_with_no_permissions!(:bob)
    end

    should "be denied POST #create access" do
      post :create, :estimate_id => @estimate.id, :estimate_line => {}
      assert_template "shared/rescues/unauthorized"
    end

    should "be denied PUT #update access" do
      put :update, :estimate_id => @estimate.id, :id => @estimate_line.id, :estimate_line => {}
      assert_template "shared/rescues/unauthorized"
    end

    should "be denied POST #destroy_collection access" do
      post :destroy_collection, :estimate_id => @estimate.id, :ids => @estimate_line.id, :estimate_line => {}
      assert_template "shared/rescues/unauthorized"
    end
  end

  context "A logged in user with the :edit_estimates permission" do
    setup do
      @bob = login_with_permissions!(:bob, :edit_estimates)
    end

    should "create an EstimateLine" do
      assert_difference @estimate.lines, :count, +1 do
        post :create, :estimate_id => @estimate.id, :estimate_line => {:description => "Killimanjaro"}
      end
    end

  end
end
