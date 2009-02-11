require File.dirname(__FILE__) + '/../test_helper'

class SlugTest < Test::Unit::TestCase
  def test_downcases_everything
    assert_equal "abc", "AbC".to_slug
  end

  def test_replaces_spaces_with_dashes
    assert_equal "a-b", "a b".to_slug
  end

  def test_keeps_digits_the_same
    assert_equal "123", "123".to_slug
  end

  def test_replaces_non_word_char_with_underscore
    assert_equal "it_s-time-for-lunch", "It's time for lunch".to_slug
  end

  def test_does_not_keep_trailing_underscores
    assert_equal "abc", "abc!".to_slug
  end

  def test_strips_before_working
    assert_equal "abc", "  abc  ".to_slug
  end

  def test_keeps_fullstop
    assert_equal "canton.css", "canton.css".to_slug
  end
end
