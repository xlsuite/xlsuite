require "#{File.dirname(__FILE__)}/../test_helper"

class ForumsCrudTest < ActionController::IntegrationTest
  include XlSuiteIntegrationHelpers

  def setup
    host! Account.find(:first).domains.first.name
    Layout.delete_all
  end

  def test_authenticated_can_create_post_in_existing_forum
    login(parties(:mary).main_email.address, "test")
    parties(:mary).permissions(true).delete(Permission.find_or_create_by_name("admin_forum"))

    get forum_categories_path
    assert_response :success
    assert_select "a[href$=?]", new_forum_category_forum_topic_path(forum_categories(:programming), forums(:rails)), /add new topic/i

    get new_forum_category_forum_topic_path(forum_categories(:programming), forums(:rails))
    assert_response :success
    assert_select "form[action$=?][method=post]", forum_category_forum_topics_path(forum_categories(:programming), forums(:rails)) do
      assert_select "input[name=?]", "topic[sticky]", {:count => 0}, "Non-admins should not be able to set the sticky attribute"
      assert_select "input[name=?]", "topic[locked]", {:count => 0}, "Non-admins should not be able to set the locked attribute"
      assert_select "input[name=?]", "topic[title]", :count => 1
      assert_select "textarea[name=?]", "topic[body]", :count => 1
      assert_select "input[type=submit]", :count => 1
      assert_select "a[href$=?]", forum_categories_path, /cancel/i
    end

    assert_difference ForumCategory, :count, 0 do
      assert_difference Forum, :count, 0 do
        assert_difference ForumTopic, :count, 1 do
          assert_difference ForumPost, :count, 1 do
            post forum_category_forum_topics_path(forum_categories(:programming), forums(:rails)),
                :topic => {:title => "Enjoy the silence", :body => "This is the silence when things can go wrong"}
            assert_response :redirect
            assert_redirected_to forum_category_forum_topic_path(forum_categories(:programming), forums(:rails), assigns(:topic))
          end
        end
      end
    end

    @topic = forums(:rails).topics.find_by_title("Enjoy the silence")
    assert_not_nil @topic, "Could not find newly created topic by title"

    get forum_categories_path
    assert_response :success
    assert_select "a[href$=?]", forum_category_forum_topic_path(forum_categories(:programming), forums(:rails), @topic), @topic.title, :count => 1
    assert_select "a.edit[href$=?]", edit_forum_category_forum_topic_path(forum_categories(:programming), forums(:rails), @topic),
        {:text => "Edit", :count => 1}, "Topic author should be able to edit topic"
    assert_select "a.edit[href$=?]", forum_category_forum_topic_path(forum_categories(:programming), forums(:rails), @topic),
        {:text => "Delete", :count => 1}, "Topic author should be able to edit topic"

    open_session do |s|
      s.host! Account.find(:first).domains.first.name
      s.post sessions_path, :user => {:email => parties(:john).main_email.address, :password => "test"}
      s.assert_response :redirect
      # We are redirecting users to the forums if they are not in the Access group
      s.assert_redirected_to forum_categories_url
      parties(:john).permissions(true).delete(Permission.find_or_create_by_name("admin_forum"))

      s.get forum_categories_path
      s.assert_response :success
      s.assert_select "a[href$=?]", forum_category_forum_topic_path(forum_categories(:programming), forums(:rails), @topic), @topic.title, :count => 1
      s.assert_select "a.edit[href$=?]", edit_forum_category_forum_topic_path(forum_categories(:programming), forums(:rails), @topic),
          {:text => "Edit", :count => 0}, "Non admin and not topic author should not be able to edit topic"
      s.assert_select "a.edit[href$=?]", forum_category_forum_topic_path(forum_categories(:programming), forums(:rails), @topic),
          {:text => "Delete", :count => 0}, "Non admin and not topic author should not be able to edit topic"
    end

    open_session do |s|
      s.host! Account.find(:first).domains.first.name

      parties(:bob).append_permissions(:admin_forum)
      s.post sessions_path, :user => {:email => parties(:bob).main_email.address, :password => "test"}
      s.assert_response :redirect
      # We are redirecting owners to the blank_landing_url intead of the forums
      s.assert_redirected_to blank_landing_url

      s.get forum_categories_path
      s.assert_response :success
      logger.debug {"===> Searching for: #{edit_forum_category_forum_topic_path(forum_categories(:programming), forums(:rails), @topic)}"}
      s.assert_select "a.edit[href$=?]", edit_forum_category_forum_topic_path(forum_categories(:programming), forums(:rails), @topic),
          {:text => "Edit", :count => 1}, "Admins should be able to edit a topic"
      logger.debug {"===> Searching for: #{forum_category_forum_topic_path(forum_categories(:programming), forums(:rails), @topic)}"}
      s.assert_select "a.edit[href$=?]", forum_category_forum_topic_path(forum_categories(:programming), forums(:rails), @topic),
          {:text => "Delete", :count => 1}, "Admins should be able to delete a topic"

      s.get forum_category_forum_topic_path(forum_categories(:programming), forums(:rails), @topic)
      s.assert_response :success
      s.assert_select "a[href*=?] img.editEdit",
          edit_forum_category_forum_topic_post_path(forum_categories(:programming), forums(:rails), @topic, @topic.posts.first), {:count => 1},
          "Admins should be able to edit a post"
      s.assert_select "a[href*=?] img.editDelete",
          forum_category_forum_topic_post_path(forum_categories(:programming), forums(:rails), @topic, @topic.posts.first), {:count => 1},
          "Admins should be able to delete a post"

      s.delete forum_category_forum_topic_post_path(forum_categories(:programming), forums(:rails), @topic, @topic.posts.first)
      s.assert_response :redirect
      s.assert_redirected_to forum_categories_path

      s.follow_redirect!
      s.assert_response :success
      s.assert_raises(ActiveRecord::RecordNotFound) { @topic.reload }
    end
  end
end
