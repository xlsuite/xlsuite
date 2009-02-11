require 'test/unit'
require 'feed_tools'
require 'feed_tools/helpers/feed_tools_helper'

class EncodingTest < Test::Unit::TestCase
  include FeedTools::FeedToolsHelper
  
  def setup
    FeedTools.reset_configurations
    FeedTools.configurations[:tidy_enabled] = false
    FeedTools.configurations[:feed_cache] = "FeedTools::DatabaseFeedCache"
    FeedTools::FeedToolsHelper.default_local_path = 
      File.expand_path(
        File.expand_path(File.dirname(__FILE__)) + '/../feeds')
  end
  
  def test_http_headers_nil
    with_feed(:from_url =>
        'http://rss.slashdot.org/Slashdot/slashdot') { |feed|
      assert_equal(false, feed.http_headers.blank?)
      assert_equal('http://rss.slashdot.org/Slashdot/slashdot', feed.url)
      feed.feed_data = <<-FEED
        <rss>
          <channel>
            <title>Feed Title</title>
          </channel>
        </rss>
      FEED
      assert_equal(true, feed.http_headers.blank?)
      assert_equal(nil, feed.url)
    }
  end
  
  def test_encoding_from_instruct
    with_feed(:from_data => <<-FEED
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
      </rss>
    FEED
    ) { |feed|
      assert_equal("utf-8", feed.encoding_from_feed_data)
      assert_equal("utf-8", feed.encoding)
    }

    with_feed(:from_data => <<-FEED
      <?xml     encoding="US-ascii"     version="1.0"     ?>
      <rss version="2.0">
      </rss>
    FEED
    ) { |feed|
      assert_equal("us-ascii", feed.encoding_from_feed_data)
      assert_equal("us-ascii", feed.encoding)
    }

    with_feed(:from_data => <<-FEED
      <?xml encoding="US-ascii"?>
      <rss version="2.0">
      </rss>
    FEED
    ) { |feed|
      assert_equal("us-ascii", feed.encoding_from_feed_data)
      assert_equal("us-ascii", feed.encoding)
    }

    with_feed(:from_data => <<-FEED
      <?xml     encoding="big5"     ?>
      <rss version="2.0">
      </rss>
    FEED
    ) { |feed|
      assert_equal("big5", feed.encoding_from_feed_data)
      assert_equal("big5", feed.encoding)
    }

    with_feed(:from_data => <<-FEED
      <?xml  bogus="crap"   encoding="mac"    bogus="crap" ?>
      <rss version="2.0">
      </rss>
    FEED
    ) { |feed|
      assert_equal("mac", feed.encoding_from_feed_data)
      assert_equal("mac", feed.encoding)
    }
  end
  
  def test_ebcdic
    with_feed(:from_file =>
        '/wellformed/encoding/x80_ebcdic-cp-us.xml') { |feed|
      assert_equal("ebcdic-cp-us", feed.encoding)
    }
  end

  def test_big_5
    with_feed(:from_file =>
        '/wellformed/encoding/big5.xml') { |feed|
      assert_equal("big5", feed.encoding)
    }
  end
end