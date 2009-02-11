require File.dirname(__FILE__) + '/../test_helper'
require 'feeds_controller'

# Re-raise errors caught by the controller.
class FeedsController; def rescue_action(e) raise e end; end

class FeedsControllerTest < Test::Unit::TestCase
  def setup
    @controller = FeedsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @bob = login_with_permissions!(:bob, :edit_feeds)

    @blog = feeds(:bobs_blog)
    @id = @blog.id
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'index'
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:feed)
  end

  def test_create
    assert_difference Feed, :count, 1 do
      post :create, :feed => {:url => 'http://bladibla.com/'}
      assert_redirected_to feeds_url
    end
  end

  def test_create_with_tags
    assert_difference Feed, :count, 1 do
      post :create, :feed => {:url => 'http://bladibla.com/', :tag_list => "programming"}
      assert_redirected_to feeds_url
      @feed = assigns(:feed)
      assert_kind_of Feed, @feed
      @feed.reload
      assert_equal 1, @feed.tags.size
      assert_equal "programming", @feed.tag_list
    end
  end

  def test_edit
    get :edit, :id => @id

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:feed)
    assert assigns(:feed).valid?
  end

  def test_update
    put :update, :id => @id, :feed => {}
    assert_response :redirect
    assert_redirected_to feeds_url
  end

  def test_destroy
    assert_not_nil Feed.find(@id)

    delete :destroy, :id => @id
    assert_redirected_to feeds_url

    assert_raise(ActiveRecord::RecordNotFound) do
      Feed.find(@id)
    end
  end
end

class FeedsControllerUnauthenticatedTest < Test::Unit::TestCase
  def setup
    @controller = FeedsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    get :index
  end

  def test_access_denied_unauthenticated
    assert_redirected_to new_session_path,
        "Access denied since not authenticated"
  end
end

class FeedsControllerAuthenticatedSansPermissionTest < Test::Unit::TestCase
  def setup
    @controller = FeedsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @bob = login_with_no_permissions!(:bob)

    get :index
  end

  def test_access_denied_no_permission
    assert_template "shared/rescues/unauthorized",
        "Access denied because :feeds permission not granted to Bob"
  end
end
