require File.dirname(__FILE__) + '/../test_helper'
require 'forum_categories_controller'

# Re-raise errors caught by the controller.
class ForumCategoriesController; def rescue_action(e) raise e end; end

class NotLoggedInUserForumCategoriesControllerTest < Test::Unit::TestCase
  def setup
    @controller = ForumCategoriesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert !assigns(:forum_categories).blank?
    assert_template "forum_categories/index"
  end

  def test_should_get_show
    get :show, :id => forum_categories(:programming).id
    assert !assigns(:forums).blank?
    assert_template "forum_categories/show"
  end

  def test_should_not_get_new
    get :new
    assert_redirected_to new_session_path
  end

  def test_should_not_get_edit
    get :edit
    assert_redirected_to new_session_path
  end

  def test_should_not_update
    put :update, :id => forum_categories(:programming).id, 
        :forum_category => {:description => "Anything related to programming"}
    forum_categories(:programming).reload
    assert_equal nil, forum_categories(:programming).description
    assert_redirected_to new_session_path
  end

  def test_should_not_delete
    count = ForumCategory.count
    delete :destroy, :id => forum_categories(:programming).id
    assert_equal count, ForumCategory.count
    assert_redirected_to new_session_path
  end
end

class LoggedInWithNoPermissionForumCategoriesControllerTest < Test::Unit::TestCase
  def setup
    @controller = ForumCategoriesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    @bob = parties(:bob)
    login_with_no_permissions!(:bob)
  end

  def test_should_not_get_new
    get :new
    assert_template "shared/rescues/unauthorized"
  end

  def test_should_not_get_edit
    get :edit
    assert_template "shared/rescues/unauthorized"
  end

  def test_should_not_delete
    count = ForumCategory.count
    delete :destroy, :id => forum_categories(:programming).id
    assert_equal count, ForumCategory.count
    assert_template "shared/rescues/unauthorized"
  end
end

class LoggedInWithAdminForumPermissionForumCategoriesControllerTest < Test::Unit::TestCase
  def setup
    @controller = ForumCategoriesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    @bob = parties(:bob)
    login_with_permissions!(:bob, :admin_forum)
  end

  def test_should_get_new
    get :new
    assert_template "forum_categories/new"
  end

  def test_should_get_edit
    get :edit, :id => forum_categories(:programming)
    assert_template "forum_categories/edit"
  end

  def test_should_update
    put :update, :id => forum_categories(:programming).id, 
        :forum_category => {:description => "Anything related to programming"}
    forum_categories(:programming).reload
    assert_equal "Anything related to programming", forum_categories(:programming).description
    assert_redirected_to forum_categories_path
  end

  def test_should_delete
    count = ForumCategory.count
    delete :destroy, :id => forum_categories(:programming).id
    assert_equal count-1, ForumCategory.count
    assert_redirected_to forum_categories_path
  end
end

class MultiAccountForumCategoriesTest < Test::Unit::TestCase
  def setup
    @controller = ForumCategoriesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @bob = login_with_permissions!(:bob, :admin_forum)

    @acct = create_new_account
    @fc = @acct.forum_categories.create!(:name => "East/West")
  end

  def test_should_not_index_forum_categories_in_other_accounts
    get :index
    assert_response :success
    assert_select "a[href$=?]", forum_category_path(@fc.id), :count => 0
    assert !assigns(:forum_categories).include?(@fc),
        "Forum Category from separate account should not be in the list of categories to show"
  end

  def test_should_not_show_forum_categories_from_other_accounts
    assert_raises(ActiveRecord::RecordNotFound) do
      get :show, :id => @fc.id
    end
  end

  def test_should_not_edit_forum_categories_from_other_accounts
    assert_raises(ActiveRecord::RecordNotFound) do
      get :edit, :id => @fc.id
    end
  end

  def test_should_not_update_forum_categories_from_other_accounts
    assert_raises(ActiveRecord::RecordNotFound) do
      put :update, :id => @fc.id, :forum_category => {:name => "West/East"}
    end
  end

  def test_should_not_destroy_forum_categories_from_other_accounts
    assert_raises(ActiveRecord::RecordNotFound) do
      delete :destroy, :id => @fc.id
    end
  end

  def test_should_create_in_own_account
    post :create, :forum_category => {:name => "North/South"}
    assert_response :redirect
    assert_redirected_to forum_categories_path

    assert_equal @bob.account, assigns(:forum_category).account
  end
end
