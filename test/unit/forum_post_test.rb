require File.dirname(__FILE__) + '/../test_helper'

class ForumPostTest < Test::Unit::TestCase
  def test_should_select_posts
    assert_equal [forum_posts(:pdi), forum_posts(:pdi_reply), forum_posts(:pdi_rebuttal)], forum_topics(:pdi).posts
  end
  
  def test_should_find_topic
    assert_equal forum_topics(:pdi), forum_posts(:pdi_reply).topic
  end

  def test_should_require_body_for_post
    p = forum_topics(:pdi).posts.build
    p.valid?
    assert p.errors.on(:body)
  end

  def test_should_create_reply
    counts = lambda { [ForumPost.count, forums(:rails).posts_count, parties(:mary).posts_count, forum_topics(:pdi).posts_count] }
    equal  = lambda { [forums(:rails).topics_count] }
    old_counts = counts.call
    old_equal  = equal.call
    
    p = create_post forum_topics(:pdi), :body => 'blah'
    assert_valid p

    [forums(:rails), parties(:mary), forum_topics(:pdi)].each &:reload
    
    assert_equal old_counts.collect { |n| n + 1}, counts.call
    assert_equal old_equal, equal.call
  end

  def test_should_update_cached_data
    p = create_post forum_topics(:pdi), :body => 'ok, ill get right on it'
    assert_valid p
    forum_topics(:pdi).reload
    assert_equal p.id, forum_topics(:pdi).last_post_id
    assert_equal p.user_id, forum_topics(:pdi).replied_by
    assert_equal p.created_at.to_i, forum_topics(:pdi).replied_at.to_i
  end

  def test_should_delete_last_post_and_fix_topic_cached_data
    forum_posts(:pdi_rebuttal).destroy
    assert_equal forum_posts(:pdi_reply).id, forum_topics(:pdi).last_post_id
    assert_equal forum_posts(:pdi_reply).user_id, forum_topics(:pdi).replied_by
    assert_equal forum_posts(:pdi_reply).created_at.to_i, forum_topics(:pdi).replied_at.to_i
  end

  def test_should_create_reply_and_set_forum_from_topic
    p = create_post forum_topics(:pdi), :body => 'blah'
    assert_equal forum_topics(:pdi).forum_id, p.forum_id
  end

  def test_should_delete_reply
    counts = lambda { [ForumPost.count, forums(:rails).posts_count, parties(:bob).posts_count, forum_topics(:pdi).posts_count] }
    equal  = lambda { [forums(:rails).topics_count] }
    old_counts = counts.call
    old_equal  = equal.call
    forum_posts(:pdi_reply).destroy
    [forums(:rails), parties(:bob), forum_topics(:pdi)].each &:reload
    assert_equal old_counts.collect { |n| n - 1}, counts.call
    assert_equal old_equal, equal.call
  end

  def test_should_edit_own_post
    assert forum_posts(:shield).editable_by?(parties(:bob))
  end
  
  def test_should_have_signature
    parties(:mary).update_attribute(:signature, "Test Signature")
    p = create_post forum_topics(:pdi), :body => 'blah'
    assert_equal 'blah\nTest Signature', p.body
  end

  #def test_should_edit_post_as_admin
  #  assert forum_posts(:shield).editable_by?(parties(:mary))
  #end

  #def test_should_edit_post_as_moderator
  #  assert forum_posts(:pdi).editable_by?(parties(:bob))
  #end

  def test_should_not_edit_post_in_own_topic
    assert !forum_posts(:shield_reply).editable_by?(parties(:bob))
  end

  protected
    def create_post(topic, options = {})
      returning topic.posts.build(options) do |p|
        p.user = parties(:mary)
        p.forum_category = topic.forum_category
        p.forum = topic.forum
        p.save!
      end
    end
end
