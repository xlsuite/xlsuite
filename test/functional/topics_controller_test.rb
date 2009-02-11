require File.dirname(__FILE__) + '/../test_helper'
require 'topics_controller'

# Re-raise errors caught by the controller.
class TopicsController; def rescue_action(e) raise e end; end

class TopicsControllerTest < Test::Unit::TestCase
  def setup
    @controller = TopicsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @account = parties(:bob).account
  end

  def test_should_get_index
    @controller.expects(:current_account).returns(@account)
    get :index, :forum_category_id => forum_categories(:programming).id, :forum_id => 1
    assert_response :success
    assert_template "topics/index"
  end

  def test_should_get_new
    login_with_permissions!(:bob, :admin_forum)
    get :new, :forum_category_id => forum_categories(:programming).id, :forum_id => 1
    assert_response :success
  end

  def test_sticky_and_locked_protected_from_non_admin
    login_with_no_permissions!(:bob)
    post :create, :forum_category_id => forums(:rails).forum_category.id, :forum_id => forums(:rails).id, :topic => { :title => 'blah', :sticky => "1", :locked => "1", :body => 'foo' }
    assert assigns(:topic)
    assert ! assigns(:topic).sticky?
    assert ! assigns(:topic).locked?
  end
    
  def test_should_allow_admin_to_sticky_and_lock
    login_with_permissions!(:bob, :admin_forum)
    post :create, :forum_category_id => forums(:rails).forum_category.id, :forum_id => forums(:rails).id, :topic => { :title => 'blah2', :sticky => "1", :locked => "1", :body => 'foo' }
    assert assigns(:topic).sticky?
    assert assigns(:topic).locked?
  end

  def test_should_create_topic
    counts = lambda { [ForumTopic.count, ForumPost.count, forums(:rails).topics_count, forums(:rails).posts_count,  parties(:bob).posts_count] }
    old = counts.call
    
    login_with_permissions!(:bob, :admin_forum)
    post :create, :forum_category_id => forums(:rails).forum_category.id, :forum_id => forums(:rails).id, :topic => { :title => 'blah', :body => 'foo' }
    assert assigns(:topic)
    assert assigns(:post)
    [forums(:rails), parties(:bob)].each &:reload
  
    assert_equal old.collect { |n| n + 1}, counts.call
  end

  def test_should_delete_topic
    counts = lambda { [ForumPost.count, forums(:rails).topics_count, forums(:rails).posts_count] }
    old = counts.call
    
    login_with_permissions!(:bob, :admin_forum)
    delete :destroy, :forum_category_id => forums(:rails).forum_category.id, :forum_id => forums(:rails).id, :id => forum_topics(:ponies).id
    [forums(:rails), parties(:bob)].each &:reload

    assert_equal old.collect { |n| n - 1}, counts.call
  end

  def test_should_update_views_for_show
    assert_difference forum_topics(:pdi), :views do
      get :show, :forum_category_id => forums(:rails).forum_category.id, :forum_id => forums(:rails).id, :id => forum_topics(:pdi).id
      assert_response :success
      forum_topics(:pdi).reload
    end
  end

  def test_should_update_views_for_show_except_topic_author
    login_with_no_permissions!(:mary)
    assert_difference forum_topics(:pdi), :views, 0 do
      get :show, :forum_category_id => forums(:rails).forum_category.id, :forum_id => forums(:rails).id, :id => forum_topics(:pdi).id
      assert_response :success
      forum_topics(:pdi).reload
    end
  end

  def test_should_show_topic
    get :show, :forum_category_id => forums(:rails).forum_category.id, :forum_id => forums(:rails).id, :id => forum_topics(:pdi).id
    assert_response :success
    assert_equal forum_topics(:pdi), assigns(:topic)
    assert_models_equal [forum_posts(:pdi), forum_posts(:pdi_reply), forum_posts(:pdi_rebuttal)], assigns(:posts)
  end

  def test_should_show_other_post
    get :show, :forum_category_id => forums(:rails).forum_category.id, :forum_id => forums(:rails).id, :id => forum_topics(:ponies).id
    assert_response :success
    assert_equal forum_topics(:ponies), assigns(:topic)
    assert_models_equal [forum_posts(:ponies)], assigns(:posts)
  end

  def test_should_get_edit
    login_with_permissions!(:bob, :admin_forum)
    get :edit, :forum_category_id => forum_categories(:programming).id, :forum_id => 1, :id => 1
    assert_response :success
  end
  
  def test_should_update_own_post
    login_with_no_permissions!(:mary)
    put :update, :forum_category_id => forums(:rails).forum_category.id,
        :forum_id => forums(:rails).id, :id => forum_topics(:ponies).id,
        :topic => { :forum_category_id => forums(:rails).forum_category.id,
        :forum_id => forums(:rails).id }
    assert_response :redirect, @response.body
    assert_redirected_to forum_category_forum_topic_path(forums(:rails).forum_category, forums(:rails), assigns(:topic))
  end

  def test_should_not_update_user_id_of_own_post
    login_with_no_permissions!(:mary)
    put :update, :forum_category_id => forums(:rails).forum_category.id,
        :forum_id => forums(:rails).id, :id => forum_topics(:ponies).id,
        :topic => { :user_id => 32, :forum_category_id => forums(:rails).forum_category.id,
        :forum_id => forums(:rails).id }
    assert_redirected_to forum_category_forum_topic_path(forums(:rails).forum_category, forums(:rails), assigns(:topic))
    assert_equal parties(:bob).id, forum_posts(:ponies).reload.user_id
  end

  def test_should_not_update_other_post
    login_with_no_permissions!(:mary)
    put :update, :forum_category_id => forums(:comics).forum_category.id,
        :forum_id => forums(:comics).id, :id => forum_topics(:galactus).id,
        :topic => { }
    assert_template "shared/rescues/unauthorized"
  end

  def test_should_update_other_post_as_admin
    login_with_permissions!(:bob, :admin_forum)
    put :update, :forum_category_id => forums(:rails).forum_category.id, :forum_id => forums(:rails).id, 
        :id => forum_topics(:ponies), :topic => { :forum_category_id => forums(:rails).forum_category.id, :forum_id => forums(:rails).id }
    assert_redirected_to forum_category_forum_topic_path(forums(:rails).forum_category, forums(:rails), assigns(:topic))
  end
end
