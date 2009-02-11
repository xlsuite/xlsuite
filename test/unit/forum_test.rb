require File.dirname(__FILE__) + '/../test_helper'

class ForumTest < Test::Unit::TestCase
  def test_should_have_associated_account
    @account = Account.find(:first)
    forum = @account.forums.create(:name => 'Test Forum')
    assert_equal @account, forum.account
  end
  
  def test_should_list_only_top_level_topics
    assert_models_equal [forum_topics(:sticky), forum_topics(:i18n), forum_topics(:ponies), forum_topics(:pdi)], forums(:rails).topics
  end

  def test_should_list_recent_posts
    assert_models_equal [forum_posts(:i18n), forum_posts(:ponies), forum_posts(:pdi_rebuttal), forum_posts(:pdi_reply), forum_posts(:pdi),forum_posts(:sticky) ], forums(:rails).posts
  end

  def test_should_find_last_post
    assert_equal forum_posts(:i18n), forums(:rails).posts.last
  end
end

class PrivateForumTest < Test::Unit::TestCase
  def setup
    @account = Account.find(:first)
    @forum = @account.forums.create!(:name => "a forum", :forum_category => ForumCategory.find(:first))

    @mary = parties(:mary)
    @bob = parties(:bob)

    @mary_group = @account.groups.create!(:name => "mary")
    @mary_group.parties << @mary
  end

  def test_readable_by_all_by_default
    assert @forum.readable_by?(@mary) && @forum.readable_by?(@bob),
        "Forum should be readable by all by default"
  end

  def test_writable_by_all_by_default
    assert @forum.writeable_by?(@mary) && @forum.writeable_by?(@bob),
        "Forum should be writeable by all by default"
  end

  def test_readable_by_one_implies_not_readable_by_others
    @forum.readers << @mary_group
    assert @forum.readable_by?(@mary),
        "Forum should be readable by Mary when Mary's group is part of the readers list"
    deny @forum.readable_by?(@bob), 
        "Forum should not be readable by Bob when Mary's group is part of the readers list"
  end

  def test_writeable_by_one_implies_not_writeable_by_others
    @forum.writers << @mary_group
    assert @forum.writeable_by?(@mary),
        "Forum should be writeable by Mary when Mary's group is part of the writers list"
    deny @forum.writeable_by?(@bob), 
        "Forum should not be writeable by Bob when Mary's group is part of the writers list"
  end

  def test_being_a_writer_implies_being_a_reader_on_a_read_limited_forum
    @forum.readers << @account.groups.create!(:name => "Readers")
    @forum.writers << @mary_group
    assert @forum.readable_by?(@mary),
        "Forum should be readable by Mary when Mary's group is part of the writers list"
  end
end

class UpdatingForumCategoryOfForum < Test::Unit::TestCase

  def test_updating_forum_category_should_update_forum_category_of_topics_and_their_post
    forum = forums(:rails)
    forum.forum_category_id = forum_categories(:books).id
    forum.save!

    for ft in forum.topics
      assert_equal ft.forum_category_id, forum_categories(:books).id
    end
    for fp in forum.posts
      assert_equal fp.forum_category_id, forum_categories(:books).id
    end
  end
end