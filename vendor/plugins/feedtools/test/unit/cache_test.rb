require 'test/unit'
require 'feed_tools'
require 'feed_tools/helpers/feed_tools_helper'

class CacheTest < Test::Unit::TestCase
  include FeedTools::FeedToolsHelper

  def setup
    FeedTools.reset_configurations
    FeedTools.configurations[:tidy_enabled] = false
    FeedTools.configurations[:feed_cache] = "FeedTools::DatabaseFeedCache"
    FeedTools::FeedToolsHelper.default_local_path = 
      File.expand_path(
        File.expand_path(File.dirname(__FILE__)) + '/../feeds')
  end

  def test_database_connection
    # Ensure the cache is on for this test
    FeedTools.configurations[:feed_cache] = "FeedTools::DatabaseFeedCache"
    unless FeedTools.feed_cache.nil?
      # Assumes that there is a database.yml file handy
      assert_equal(true, FeedTools.feed_cache_connected?)
    else
      puts "\nSkipping cache test since the cache is still disabled.\n"
    end
  end
  
  def test_redirects_when_cache_disabled
    # Turn the cache off for this test
    FeedTools.configurations[:feed_cache] = nil
    # We just want to make sure there's no unexpected exceptions
    begin
      slashdot_feed = FeedTools::Feed.open('http://www.slashdot.org/index.rss')
    rescue FeedTools::FeedAccessError
    end
    
    # Turn the cache back on
    FeedTools.configurations[:feed_cache] = "FeedTools::DatabaseFeedCache"
  end

  def test_redirects_when_cache_enabled
    # Ensure the cache is on for this test
    FeedTools.configurations[:feed_cache] = "FeedTools::DatabaseFeedCache"
    begin
      slashdot_feed = FeedTools::Feed.open(
        'http://www.slashdot.org/index.rss')
      assert(slashdot_feed.feed_data != nil, "No content retrieved.")
      assert(slashdot_feed.configurations[:feed_cache] != nil)
      assert_equal(false, slashdot_feed.href.blank?)
      slashdot_feed.expire!
      slashdot_feed.expire!
      assert_equal(true, slashdot_feed.expired?)
      assert_equal(false, slashdot_feed.href.blank?)
      slashdot_feed = FeedTools::Feed.open(
        'http://www.slashdot.org/index.rss')
      assert(slashdot_feed.feed_data != nil, "No content retrieved.")
      assert(slashdot_feed.configurations[:feed_cache] != nil)
      assert_equal(true, slashdot_feed.live?)
      assert_equal(false, slashdot_feed.href.blank?)
      slashdot_feed = FeedTools::Feed.open(
        'http://www.slashdot.org/index.rss')
      assert(slashdot_feed.feed_data != nil, "No content retrieved.")
      assert(slashdot_feed.configurations[:feed_cache] != nil)
      assert_equal(false, slashdot_feed.live?)
      assert_equal(false, slashdot_feed.href.blank?)
      
      # Make sure autodiscovery doesn't break the cache.
      assert_equal(slashdot_feed.href,
        FeedTools::Feed.open('http://www.slashdot.org').href)
    
      entries =
        FeedTools::DatabaseFeedCache.find_all_by_href(slashdot_feed.url)
      assert_equal(1, entries.size)
    rescue FeedTools::FeedAccessError
    end
  end
  
  def test_cached_item_expiration
    # Ensure the cache is on for this test
    FeedTools.configurations[:feed_cache] = "FeedTools::DatabaseFeedCache"
    begin
      slashdot_feed = FeedTools::Feed.open('http://www.slashdot.org/index.rss')
      assert(slashdot_feed.feed_data != nil, "No content retrieved.")
      slashdot_feed.expire!
      assert_equal(true, slashdot_feed.expired?)
      assert_equal(false, slashdot_feed.url.blank?)
      slashdot_feed = FeedTools::Feed.open('http://www.slashdot.org/index.rss')
      assert(slashdot_feed.feed_data != nil, "No content retrieved.")
      assert_equal(true, slashdot_feed.live?)
      assert_equal(false, slashdot_feed.url.blank?)
      slashdot_feed.time_to_live = 1.hour
      slashdot_feed.last_retrieved = (Time.now - 55.minute)
      assert_equal(false, slashdot_feed.expired?)
      slashdot_feed.last_retrieved = (Time.now - 61.minute)
      assert_equal(true, slashdot_feed.expired?)
    rescue FeedTools::FeedAccessError
    end
  end
  
  def test_file_protocol_url_cache_disuse
    # Ensure the cache is on for this test
    FeedTools.configurations[:feed_cache] = "FeedTools::DatabaseFeedCache"
    with_feed(:from_file => 'wellformed/rss/aaa_wellformed.xml') { |feed|
      assert_equal(nil, feed.cache_object)
    }
  end
end