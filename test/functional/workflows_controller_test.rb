require File.dirname(__FILE__) + '/../test_helper'
require 'workflows_controller'

# Re-raise errors caught by the controller.
class WorkflowsController; def rescue_action(e) raise e end; end

class WorkflowsControllerTest < Test::Unit::TestCase
  def setup
    @controller = WorkflowsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  
  context "A logged in user without edit_workflow permission" do
    setup do
      @bob = login_with_no_permissions!(:bob)
    end
    
    context "trying to access #index action" do
      setup do
        xhr :get, :index
      end
      
      should %Q!received "401 unauthorized" popup message! do
        assert_response :success
        assert_include("401 Unauthorized", @response.body)
      end
    end

    context "trying to access #create action" do
      setup do
        xhr :post, :create, :workflow => {:title => "aloha"}
      end
      
      should %Q!received "401 unauthorized" popup message! do
        assert_response :success
        assert_include("401 Unauthorized", @response.body)
      end
    end

    context "trying to access #update action" do
      setup do
        xhr :put, :update, :id => 1, :workflow => {:title => "aloha"} 
      end
      
      should %Q!received "401 unauthorized" popup message! do
        assert_response :success
        assert_include("401 Unauthorized", @response.body)
      end
    end

    context "trying to access #destroy action" do
      setup do
        xhr :delete, :destroy, :id => 1
      end
      
      should %Q!received "401 unauthorized" popup message! do
        assert_response :success
        assert_include("401 Unauthorized", @response.body)
      end
    end
    
    context "trying to access #destroy_collection action" do
      setup do
        xhr :delete, :destroy_collection, :ids => "1,2,3"
      end
      
      should %Q!received "401 unauthorized" popup message! do
        assert_response :success
        assert_include("401 Unauthorized", @response.body)
      end
    end
  end
end
