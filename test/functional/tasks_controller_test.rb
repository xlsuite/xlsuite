require File.dirname(__FILE__) + '/../test_helper'
require 'tasks_controller'

# Re-raise errors caught by the controller.
class TasksController; def rescue_action(e) raise e end; end

class TasksControllerTest < Test::Unit::TestCase
  def setup
    @controller = TasksController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  
  context "Non logged-in user" do
    context "trying to access #index action" do
      setup do
        xhr :get, :index
      end
      
      should %Q!received "you've been logged out" popup message! do
        assert_response :success
        assert_include("You\\'ve been logged out", @response.body)
      end
    end

    context "trying to access #create action" do
      setup do
        xhr :post, :create, :task => {:account_id => 1}
      end
      
      should %Q!received "you've been logged out" popup message! do
        assert_response :success
        assert_include("You\\'ve been logged out", @response.body)
      end
    end

    context "trying to access #update action" do
      setup do
        xhr :put, :update, :id => 1, :task => {:account_id => 1} 
      end
      
      should %Q!received "you've been logged out" popup message! do
        assert_response :success
        assert_include("You\\'ve been logged out", @response.body)
      end
    end

    context "trying to access #destroy action" do
      setup do
        xhr :delete, :destroy, :id => 1
      end
      
      should %Q!received "you've been logged out" popup message! do
        assert_response :success
        assert_include("You\\'ve been logged out", @response.body)
      end
    end
    
    context "trying to access #destroy_collection action" do
      setup do
        xhr :delete, :destroy_collection, :ids => "1,2,3"
      end
      
      should %Q!received "you've been logged out" popup message! do
        assert_response :success
        assert_include("You\\'ve been logged out", @response.body)
      end
    end
  end
end
