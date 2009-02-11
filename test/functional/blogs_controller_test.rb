require File.dirname(__FILE__) + '/../test_helper'
require 'blogs_controller'

# Re-raise errors caught by the controller.
class BlogsController; def rescue_action(e) raise e end; end

class BlogsControllerTest < Test::Unit::TestCase
  setup do
    @controller = BlogsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  
    @account = Account.find(:first)
  end
  
  context "Non logged in users" do    
    context "trying to access index action" do
      setup do
        get :index
      end
      
      should "get redirected to /sessions/new" do
        assert_redirected_to "/sessions/new"
      end
    end
    
    context "trying to access edit action" do
      setup do
        get :edit
      end
      
      should "get redirected to /sessions/new" do
        assert_redirected_to "/sessions/new"
      end
    end
  end
end
