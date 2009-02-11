require File.dirname(__FILE__) + '/../../test_helper'

module XlSuite
  class RenderFeedTest < Test::Unit::TestCase
    def test_does_not_change_default_options
      XlSuite::RenderFeed.new("render_feed", "labeled:'bla' count:8", "")
      @tag = XlSuite::RenderFeed.new("render_feed", "labeled:'bla'", "")
      assert_equal 5, @tag.instance_variable_get("@options")[:count],
          "DefaultOptions[:count] changed by initial tag instantiation"
    end
    
    def test_can_only_contain_one_of_labeled_or_tagged_any_or_tagged_all_option
      assert_raise SyntaxError do
        XlSuite::RenderFeed.new("render_feed", "labeled:'boo' tagged_any:'what' tagged_all:'hiya,nub'", "")
      end
      assert_raise SyntaxError do
        XlSuite::RenderFeed.new("render_feed", "tagged_any:'what' tagged_all:'hiya,nub'", "")
      end
      assert_raise SyntaxError do
        XlSuite::RenderFeed.new("render_feed", "labeled:'boo' tagged_all:'hiya,nub'", "")
      end      
      assert_raise SyntaxError do
        XlSuite::RenderFeed.new("render_feed", "labeled:'boo' tagged_any:'what'", "")
      end
    end
    
    def test_must_contain_either_labeled_or_tagged_any_or_tagged_all
      assert_raise SyntaxError do
        XlSuite::RenderFeed.new("render_feed", "count:8", "")
      end
    end
  end
end
