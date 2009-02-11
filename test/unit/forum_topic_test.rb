require File.dirname(__FILE__) + '/../test_helper'

class ForumTopicTest < Test::Unit::TestCase
  def test_knows_last_post
    assert_equal forum_posts(:pdi_rebuttal), forum_topics(:pdi).posts.last
  end
  
  def test_should_require_title_user_and_forum
    t=ForumTopic.new
    t.valid?
    assert t.errors.on(:title)
    assert t.errors.on(:user_id)
    assert t.errors.on(:forum_id)
    assert t.errors.on(:forum_category_id)
    assert ! t.save
    t.user=parties(:mary)
    t.title = "happy life"
    t.forum = forums(:rails)
    t.forum_category = forums(:rails).forum_category
    assert t.save
    assert_nil t.errors.on(:title)
    assert_nil t.errors.on(:user_id)
    assert_nil t.errors.on(:forum_id)
    assert_nil t.errors.on(:forum_category_id)
  end

  def test_should_add_to_user_counter_cache
    assert_difference ForumPost, :count do
      assert_difference parties(:bob).posts, :count do
        p = forum_topics(:pdi).posts.build(:body => "I'll do it")
        p.user = parties(:bob)
        p.forum = forum_topics(:pdi).forum
        p.forum_category = forum_topics(:pdi).forum_category
        p.save!
      end
    end
  end
 
  def test_should_create_topic
    counts = lambda { [ForumTopic.count, forums(:rails).topics_count] }
    old = counts.call
    t = forums(:rails).topics.build(:title => 'foo')
    t.user = parties(:mary)
    t.forum_category = forums(:rails).forum_category
    assert_valid t
    t.save
    [forums(:rails), parties(:mary)].each &:reload
    assert_equal old.collect { |n| n + 1}, counts.call
  end
  
  def test_should_delete_topic
    counts = lambda { [ForumTopic.count, ForumPost.count, forums(:rails).topics_count, forums(:rails).posts_count,  parties(:bob).posts_count] }
    old = counts.call
    forum_topics(:ponies).destroy
    [forums(:rails), parties(:bob)].each &:reload
    assert_equal old.collect { |n| n - 1}, counts.call
  end
  
  def test_hits
    hits = forum_topics(:pdi).views
    forum_topics(:pdi).hit!
    forum_topics(:pdi).hit!
    assert_equal(hits+2, forum_topics(:pdi).reload.hits)
    assert_equal(forum_topics(:pdi).hits, forum_topics(:pdi).views)
  end
  
  def test_replied_at_set
    t = ForumTopic.new
    t.user = parties(:mary)
    t.title = "happy life"
    t.forum = forums(:rails)
    t.forum_category = forums(:rails).forum_category
    assert t.save
    assert_not_nil t.replied_at
    assert t.replied_at <= Time.now.utc
    assert_in_delta t.replied_at, Time.now.utc, 5.seconds
  end
  
  def test_doesnt_change_replied_at_on_save
    t = ForumTopic.find(:first)
    old = t.replied_at
    assert t.save!
    assert_equal old, t.replied_at
  end
end

class UpdatingForumAndForumCategoryOfTopic < Test::Unit::TestCase

  def test_updating_forum_and_forum_category_should_update_forum_and_forum_category_of_posts
    topic = forum_topics(:pdi)
    topic.forum_category_id = forums(:comics).forum_category.id
    topic.forum_id = forums(:comics).id
    assert topic.save
    for fp in topic.posts
      assert_equal fp.forum_category_id, forums(:comics).forum_category.id
      assert_equal fp.forum_id, forums(:comics).id
    end
  end
end