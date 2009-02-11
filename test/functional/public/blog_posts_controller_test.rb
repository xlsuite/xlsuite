require File.dirname(__FILE__) + '/../../test_helper'
require 'public/blog_posts_controller'

# Re-raise errors caught by the controller.
class Public::BlogPostsController; def rescue_action(e) raise e end; end

class Public::BlogPostsControllerTest < Test::Unit::TestCase
  def setup
    @controller = Public::BlogPostsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @account = accounts(:wpul)
  end

  context "A non logged in user trying to create a blog_post" do  
    context "trying to access update action" do
      setup do
        post :update
      end
      
      should "get redirected to /sessions/new" do
        assert_redirected_to "/sessions/new"
      end
    end
  end
  
  context "A logged in user" do
    setup do
      @bob = login_with_no_permissions!(:bob)
    end
    
    context "trying to create a post" do
      context "on his own blog" do
        setup do
          @blog = @bob.blogs.create!(:account => @bob.account, :title => "bob's blog", :label => "bob", :author_name => "bob", :created_by => @bob, :owner => @bob)
          @blog_post_count = BlogPost.count
          post :create, :blog_post => {
            :title => "my first blog",
            :link => "http://ixld.com",
            :publish => true,
            :hide_comments => false,
            :deactivate_commenting_on => 1.month.from_now,
            :body => "This is the bob's blog post"}, :blog_id => @blog.id
          @blog_post = assigns(:blog_post)
        end
        
        should "create the post properly" do
          assert_equal @blog_post_count + 1, BlogPost.count
          assert_not_nil @blog_post
          assert_equal "my first blog", @blog_post.title
          assert_equal "http://ixld.com", @blog_post.link
          assert_not_nil @blog_post.published_at
          assert_equal false, @blog_post.hide_comments
          assert_equal 1.month.from_now.day, @blog_post.deactivate_commenting_on.day
          assert_equal 1.month.from_now.month, @blog_post.deactivate_commenting_on.month
          assert_equal 1.month.from_now.year, @blog_post.deactivate_commenting_on.year
          assert_equal "This is the bob's blog post", @blog_post.body
        end
      end
      
      context "on an admin blog" do
        setup do
          admin = parties(:admin)
          @blog_post_count = BlogPost.count
          @blog = admin.blogs.create!(:account => admin.account, :title => "admin's blog", :label => "admin", :author_name => "admin", :created_by => admin, :owner => admin)
          post :create, :blog_post => {
            :title => "my first blog",
            :link => "http://ixld.com",
            :publish => true,
            :hide_comments => false,
            :deactivate_commenting_on => 1.month.from_now,
            :body => "Trying to post on admin's blog"}, :blog_id => @blog.id
          @blog_post = assigns(:blog_post)
        end
        
        should "be rejected" do
          assert BlogPost.count, @blog_post_count
          assert_nil @blog_post
          assert_response 401
        end
      end
      
    end
  end
end
