require File.dirname(__FILE__) + '/../test_helper'
require 'forums_controller'

# Re-raise errors caught by the controller.
class ForumsController; def rescue_action(e) raise e end; end

class ForumsControllerTest < Test::Unit::TestCase
  
  def setup
    @controller = ForumsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @account = Account.find(:first)
  end

  def test_should_get_new
    login_with_permissions!(:bob, :admin_forum)
    get :new, :forum_category_id => forum_categories(:programming).id
    assert_response :success
  end
  
  def test_should_require_admin
    @bob = login_with_no_permissions!(:bob)
    get :new
    assert_template "shared/rescues/unauthorized"
  end
  
  def test_should_create_forum
    login_with_permissions!(:bob, :admin_forum)
    assert_difference Forum, :count do
      post :create, :forum_category_id => forum_categories(:programming).id, :forum => { :name => 'yeah' }
    end

    assert_redirected_to forum_categories_path
    assert_equal @account, Forum.find_by_name('yeah').account
  end

  def test_should_show_forum
    get :show, :forum_category_id => forum_categories(:programming).id, :id => forums(:rails).id
    assert_response :success
    assert_equal(forum_topics(:sticky), assigns(:topics).first)
  end

  def test_should_get_edit
    login_with_permissions!(:bob, :admin_forum)
    get :edit, :forum_category_id => forum_categories(:programming).id, :id => forums(:rails).id
    assert_response :success
  end

  def test_should_update_forum
    login_with_permissions!(:bob, :admin_forum)
    put :update, :forum_category_id => forum_categories(:programming).id, :id => forums(:rails).id, :forum => { }
    assert_redirected_to forum_categories_path
  end

  def test_should_destroy_forum
    login_with_permissions!(:bob, :admin_forum)
    old_count = Forum.count
    delete :destroy, :forum_category_id => forum_categories(:programming).id, :id => forums(:rails).id
    assert_equal old_count-1, Forum.count

    assert_redirected_to forum_categories_path
  end
end

class AnAnonymousPersonAccessingAForumTest < Test::Unit::TestCase
  def setup
    @controller = ForumsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @account = Account.find(:first)
    @forum_category = mock("forum category")
    @forum_category.stubs(:id).returns(457)

    @forum = mock("forum")
    @forum.stubs(:id).returns(329)
    @forum.stubs(:topics).returns(@topics_proxy = mock("topics proxy"))

    ForumCategory.stubs(:find).returns(@forum_category)
    @forum_category.stubs(:forums).returns(@forums_proxy = mock("forums proxy"))
    @forums_proxy.stubs(:find).returns(@forum)
    @topics_proxy.stubs(:find).returns([])
  end

  def test_should_be_allowed_when_readable_by_all
    @forum.expects(:readable_by?).with(nil).returns(true)
    @forum_category.expects(:name).returns("forum_name")
    get :show, :id => @forum.id, :forum_category_id => @forum_category.id
    assert_response :success
  end

  def test_should_not_be_allowed_when_not_readable_by_all
    @forum.expects(:readable_by?).with(nil).returns(false)
    get :show, :id => @forum.id, :forum_category_id => @forum_category.id
    assert_response :redirect
    assert_redirected_to new_session_path
  end
end
