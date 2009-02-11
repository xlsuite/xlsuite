require File.dirname(__FILE__) + '/../test_helper'
require 'blog_posts_controller'

# Re-raise errors caught by the controller.
class BlogPostsController; def rescue_action(e) raise e end; end

class BlogPostsControllerTest < Test::Unit::TestCase
  setup do
    @controller = BlogPostsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  
    @account = Account.find(:first)
  end
  
  context "Non logged in users" do    
    context "trying to access edit action" do
      setup do
        get :edit
      end
      
      should "get redirected to /sessions/new" do
        assert_redirected_to "/sessions/new"
      end
    end
    
    context "trying to access update action" do
      setup do
        get :update
      end
      
      should "get redirected to /sessions/new" do
        assert_redirected_to "/sessions/new"
      end
    end
  end
end
