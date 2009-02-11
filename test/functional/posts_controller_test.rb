require File.dirname(__FILE__) + '/../test_helper'
require 'posts_controller'

# Re-raise errors caught by the controller.
class PostsController; def rescue_action(e) raise e end; end

class PostsControllerTest < Test::Unit::TestCase
  
  def setup
    @controller = PostsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @account = parties(:bob).account
  end

  def test_should_create_reply
    counts = lambda { [ForumPost.count, forums(:rails).posts_count, parties(:bob).posts_count, forum_topics(:pdi).posts_count] }
    equal  = lambda { [forums(:rails).topics_count] }
    old_counts = counts.call
    old_equal  = equal.call

    login_with_no_permissions!(:bob)

    post :create, :forum_category_id => forums(:rails).forum_category.id, :forum_id => forums(:rails).id, :topic_id => forum_topics(:pdi).id, :post => { :body => 'blah' }
    assert_response :redirect
    assert_not_nil assigns(:post), "No post was created"
    assert_redirected_to forum_category_forum_topic_path(:forum_category_id => forums(:rails).forum_category.id, :forum_id => forums(:rails).id, :id => forum_topics(:pdi).id, :anchor => assigns(:post).dom_id, :page => '1', :show => "10")
    assert_equal forum_topics(:pdi), assigns(:topic)
    [forums(:rails), parties(:bob), forum_topics(:pdi)].each &:reload
  
    assert_equal old_counts.collect { |n| n + 1}, counts.call
    assert_equal old_equal, equal.call
  end

  def test_should_update_topic_replied_at_upon_replying
    login_with_no_permissions!(:bob)

    old = forum_topics(:pdi).replied_at
    post :create, :forum_category_id => forums(:rails).forum_category.id,
        :forum_id => forums(:rails).id,
        :topic_id => forum_topics(:pdi).id,
        :post => { :body => 'blah' }
    assert_response :redirect
    assert_not_equal(old, forum_topics(:pdi).reload.replied_at)
    assert old < forum_topics(:pdi).reload.replied_at
  end

  def test_should_reply_with_no_body
    login_with_no_permissions!(:bob)
    assert_difference ForumPost, :count, 0 do
      post :create, :forum_category_id => forums(:rails).forum_category.id,
          :forum_id => forums(:rails).id,
          :topic_id => forum_posts(:pdi).id,
          :post => {}
      assert_response :redirect
      assert_redirected_to forum_category_forum_topic_path(:forum_id => forums(:rails).id, :id => forum_posts(:pdi).id, :anchor => 'reply-form', :show => '10')
    end
  end

  def test_should_delete_reply
    login_with_no_permissions!(:bob)

    counts = lambda { [ForumPost.count, forums(:rails).posts_count, parties(:bob).posts_count, forum_topics(:pdi).posts_count] }
    equal  = lambda { [forums(:rails).topics_count] }
    old_counts = counts.call
    old_equal  = equal.call

    delete :destroy, :forum_category_id => forums(:rails).forum_category.id, :forum_id => forums(:rails).id, :topic_id => forum_topics(:pdi).id, :id => forum_posts(:pdi_reply).id
    [forums(:rails), parties(:bob), forum_topics(:pdi)].each &:reload

    assert_equal old_counts.collect { |n| n - 1}, counts.call
    assert_equal old_equal, equal.call
  end

  def test_should_delete_topic_if_deleting_the_last_reply
    login_with_no_permissions!(:mary)

    assert_difference ForumPost, :count, -1 do
      assert_difference ForumTopic, :count, -1 do
        delete :destroy, :forum_category_id => forums(:rails).forum_category.id, :forum_id => forums(:rails).id, :topic_id => forum_topics(:i18n).id, :id => forum_posts(:i18n).id
        assert_redirected_to forum_categories_path
        assert_raise(ActiveRecord::RecordNotFound) { forum_topics(:i18n).reload }
      end
    end
  end

  def test_can_edit_own_post
    login_with_no_permissions!(:bob)

    put :update, :forum_category_id => forums(:comics).forum_category.id,
        :forum_id => forums(:comics).id,
        :topic_id => forum_topics(:galactus).id,
        :id => forum_posts(:silver_surfer).id,
        :post => {}
    assert_response :redirect
    assert_redirected_to forum_category_forum_topic_path(:forum_category_id => forums(:comics).forum_category, :forum_id => forums(:comics), :id => forum_topics(:galactus), :anchor => forum_posts(:silver_surfer).dom_id)
  end

  def test_cannot_edit_other_post
    login_with_no_permissions!(:mary)

    put :update, :forum_category_id => forums(:comics).forum_category.id,
        :forum_id => forums(:comics).id,
        :topic_id => forum_topics(:galactus).id,
        :id => forum_posts(:galactus).id,
        :post => {}
    assert_template "shared/rescues/unauthorized"
  end

  def test_cannot_edit_own_post_user_id
    login_with_no_permissions!(:bob)

    put :update, :forum_category_id => forums(:rails).forum_category.id,
        :forum_id => forums(:rails).id,
        :topic_id => forum_topics(:pdi).id,
        :id => forum_posts(:pdi_reply).id,
        :post => { :user_id => 32 }
    assert_response :redirect
    assert_redirected_to forum_category_forum_topic_path(:forum_category_id => forums(:rails).forum_category, :forum_id => forums(:rails), :id => forum_posts(:pdi), :anchor => forum_posts(:pdi_reply).dom_id)
    assert_equal parties(:bob).id, forum_posts(:pdi_reply).reload.user_id
  end

  def test_can_edit_other_post_as_admin
    login_with_permissions!(:bob, :admin_forum)

    put :update, :forum_category_id => forums(:rails).forum_category.id,
        :forum_id => forums(:rails).id,
        :topic_id => forum_topics(:pdi).id,
        :id => forum_posts(:pdi_rebuttal).id,
        :post => {}
    assert_response :redirect
    assert_redirected_to forum_category_forum_topic_path(:forum_category_id => forums(:rails).forum_category, :forum_id => forums(:rails), :id => forum_posts(:pdi), :anchor => forum_posts(:pdi_rebuttal).dom_id)
  end
  
  def test_should_view_recent_posts
    get :index
    assert_response :success
    page = assigns(:page)
    assert_models_equal [forum_posts(:i18n), forum_posts(:shield_reply), forum_posts(:shield), forum_posts(:silver_surfer), forum_posts(:galactus), forum_posts(:ponies), forum_posts(:pdi_rebuttal), forum_posts(:pdi_reply), forum_posts(:pdi), forum_posts(:sticky)], page.items
  end
  
  def test_should_view_recent_posts_as_feed
    get :index, :format => "atom"
    assert_response :success
    assert_template "index.rxml"
  end

  def test_should_view_posts_by_forum
    get :index, :forum_category_id => forums(:comics).forum_category.id, :forum_id => forums(:comics).id
    assert_response :success
    page = assigns(:page)
    assert_models_equal [forum_posts(:shield_reply), forum_posts(:shield), forum_posts(:silver_surfer), forum_posts(:galactus)], page.items
  end

  def test_should_view_posts_by_forum_as_feed
    get :index, :forum_category_id => forums(:comics).forum_category.id,
        :forum_id => forums(:comics).id,
        :format => "atom"
    assert_response :success
    assert_template "index.rxml"
  end

  def test_should_view_posts_by_forum_and_topic_as_feed
    get :index, :forum_category_id => forums(:comics).forum_category.id, :forum_id => forums(:comics).id, :topic_id => forum_topics(:galactus).id, :format => "atom"
    assert_response :success
    assert_template "index.rxml"
  end

  def test_should_search_recent_posts
    get :index, :q => 'pdi'
    assert_response :success
    page = assigns(:page)
    assert_models_equal [forum_posts(:pdi_rebuttal), forum_posts(:pdi_reply), forum_posts(:pdi)], page.items
  end

  def test_should_search_posts_by_forum
    get :index, :forum_category_id => forums(:comics).forum_category.id, :forum_id => forums(:comics).id, :q => 'galactus'
    assert_response :success
    page = assigns(:page)
    assert_models_equal [forum_posts(:silver_surfer), forum_posts(:galactus)], page.items
  end

  def test_should_search_posts_by_user
    get :index, :user_id => parties(:bob).id, :q => 'pdi'
    assert_response :success
    page = assigns(:page)
    assert_models_equal [forum_posts(:pdi_reply)], page.items
  end
  
  def test_disallow_new_post_to_locked_topic
    galactus = forum_topics(:galactus)
    galactus.update_attribute(:locked, true)

    login_with_no_permissions!(:bob)
    post :create, :forum_category_id => forums(:comics).forum_category.id,
        :forum_id => forums(:comics).id,
        :topic_id => forum_topics(:galactus).id,
        :post => { :body => 'blah' }

    assert_redirected_to forum_category_forum_topic_path(:forum_category_id => forums(:comics).forum_category, :forum_id => forums(:comics), :id => forum_topics(:galactus))
    assert_equal 'This topic is locked.', flash[:notice]
  end
end
