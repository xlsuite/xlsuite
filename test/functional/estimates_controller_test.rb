require File.dirname(__FILE__) + '/../test_helper'
require 'estimates_controller'

# Re-raise errors caught by the controller.
class EstimatesController; def rescue_action(e) raise e end; end

class EstimatesControllerTest < Test::Unit::TestCase
  def setup
    @controller = EstimatesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @my_fish = products(:fish)
    @my_dog = products(:dog)
    @account = @my_fish.account
    @estimate = @account.estimates.create!(:customer => parties(:bob), :date => Date.today)
    EstimateLine.create!(:estimate => @estimate, :account => @account, :target_id => @my_fish.dom_id, :quantity => 2)
    EstimateLine.create!(:estimate => @estimate, :account => @account, :target_id => @my_dog.dom_id, :quantity => 3)
  end

  context "An anonymous user" do
    should "be granted access to #create" do
      post :create, :estimate => {}, :format => :js
      assert_response :success
    end

    should "be denied access to #update" do
      put :update, :id => @estimate.id, :estimate => {}
      assert_response :redirect
      assert_redirected_to new_session_path
    end
  end

  context "A logged in user without the :edit_estimates permission" do
    setup do
      @bob = login_with_no_permissions!(:bob)
    end

    should "be granted access to #create" do
      post :create, :estimate => {}, :format => :js
      assert_response :success
    end

    should "be denied access to #update" do
      put :update, :id => @estimate.id, :estimate => {}
      assert_template "shared/rescues/unauthorized"
    end
  end

  context "A user with :edit_estimates permission" do
    setup do
      @bob = login_with_permissions!(:bob, :edit_estimates)
    end

    should_be_restful do |resource|
      resource.actions = %w(create update)
      resource.create.params = {:invoice_to_id => 100001} # bob
    end
  end
end
