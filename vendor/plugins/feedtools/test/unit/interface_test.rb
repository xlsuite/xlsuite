require 'test/unit'
require 'feed_tools'
require 'feed_tools/helpers/feed_tools_helper'

class InterfaceTest < Test::Unit::TestCase
  def setup
    FeedTools.reset_configurations
    FeedTools.configurations[:tidy_enabled] = false
    FeedTools.configurations[:feed_cache] = "FeedTools::DatabaseFeedCache"
    FeedTools::FeedToolsHelper.default_local_path = 
      File.expand_path(
        File.expand_path(File.dirname(__FILE__)) + '/../feeds')
  end

  def test_feed_interface
    # These will throw an exception if missing, obviously
    feed = FeedTools::Feed.new
    feed.title
    feed.subtitle
    feed.description
    feed.link
    feed.entries
    feed.items
  end
  
  def test_feed_item_interface
    # These will throw an exception if missing, obviously
    feed_item = FeedTools::FeedItem.new
    feed_item.title
    feed_item.content
    feed_item.description
    feed_item.link
  end
end