require File.dirname(__FILE__) + '/../test_helper'

class ForumCategoryTest < Test::Unit::TestCase
  def setup
    @forum_category = forum_categories(:programming)
  end
  
  def test_destroy_should_destroy_all_children
    assert @forum_category.forums.count != 0
    assert @forum_category.topics.count != 0
    assert @forum_category.posts.count != 0
    @forum_category.destroy
    assert @forum_category.forums.count == 0
    assert @forum_category.topics.count == 0
    assert @forum_category.posts.count == 0         
  end

  def test_can_get_forums_readable_by_user_when_no_read_restriction
    assert_equal @forum_category.forums,
        @forum_category.forums.readable_by(nil),
        "readable by Anonymous"
    assert_equal @forum_category.forums,
        @forum_category.forums.readable_by(parties(:bob)),
        "readable by Bob"
  end

  def test_can_get_forums_readable_by_user_when_read_restrictions_apply
    @forum_category.forums.clear
    f = @forum_category.forums.create!(:name => "ABC", :account => @forum_category.account)
    f.readers << g = Group.create!(:name => "Members", :account => @forum_category.account)
    g.parties << parties(:bob)

    assert_equal [], @forum_category.forums.readable_by(nil),
        "NOT-readable by Anonymous"
    assert_equal [f], @forum_category.forums.readable_by(parties(:bob)),
        "readable by Bob"
  end

  def test_can_get_forums_writeable_by_user_when_no_write_restriction
    assert_equal @forum_category.forums,
        @forum_category.forums.readable_by(nil),
        "readable by Anonymous"
    assert_equal @forum_category.forums,
        @forum_category.forums.readable_by(parties(:bob)),
        "readable by Bob"
  end

  def test_can_get_forums_writeable_by_user_when_write_restriction_apply
    @forum_category.forums.clear
    f = @forum_category.forums.create!(:name => "ABC", :account => @forum_category.account)
    f.writers << g = Group.create!(:name => "Members", :account => @forum_category.account)
    g.parties << parties(:bob)

    assert_equal [], @forum_category.forums.writeable_by(nil),
        "NOT-readable by Anonymous"
    assert_equal [f], @forum_category.forums.writeable_by(parties(:bob)),
        "writeable by Bob"
  end

  def test_create_with_blank_name
    forum_category = ForumCategory.create(:name => "")
    assert_match(/can't\sbe\sblank/, forum_category.errors.full_messages.join(','))
  end
end
