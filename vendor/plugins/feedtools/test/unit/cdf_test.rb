require 'test/unit'
require 'feed_tools'
require 'feed_tools/helpers/feed_tools_helper'

class CdfTest < Test::Unit::TestCase
  include FeedTools::FeedToolsHelper
  
  def setup
    FeedTools.reset_configurations
    FeedTools.configurations[:tidy_enabled] = false
    FeedTools.configurations[:feed_cache] = "FeedTools::DatabaseFeedCache"
    FeedTools::FeedToolsHelper.default_local_path = 
      File.expand_path(
        File.expand_path(File.dirname(__FILE__)) + '/../feeds')
  end

  def test_feed_title
    with_feed(:from_data => <<-FEED
      <CHANNEL>
        <TITLE>Example Title</TITLE>
      </CHANNEL>
    FEED
    ) { |feed|              
      assert_equal("Example Title", feed.title)
    }
    with_feed(:from_file => 'wellformed/cdf/channel_title.xml') { |feed|
    assert_equal("Example feed", feed.title)
    }
  end

  def test_feed_description
    with_feed(:from_file => 'wellformed/cdf/channel_abstract_map_description.xml') { |feed|
      assert_equal("Example description", feed.description)
    }
    with_feed(:from_file => 'wellformed/cdf/channel_abstract_map_tagline.xml') { |feed|
      assert_equal("Example description", feed.tagline)
    }
  end
  
  def test_feed_href
    with_feed(:from_data => <<-FEED
      <CHANNEL HREF="http://www.example.com/">
      </CHANNEL>
    FEED
    ) { |feed|
      assert_equal("http://www.example.com/", feed.link)
    }
    with_feed(:from_file => 'wellformed/cdf/channel_href_map_link.xml') { |feed|
      assert_equal("http://www.example.org/", feed.link)
    }
  end

  def test_feed_links
    # TODO
  end

  def test_feed_images
    with_feed(:from_data => <<-FEED
      <CHANNEL>
        <LOGO HREF="http://www.example.com/exampleicon.gif" STYLE="ICON" />
        <LOGO HREF="http://www.example.com/exampleimage.gif" STYLE="IMAGE" />
      </CHANNEL>
    FEED
    ) { |feed|
      assert_equal(2, feed.images.size)
      assert_equal("http://www.example.com/exampleicon.gif", feed.images[0].url)
      assert_equal("icon", feed.images[0].style)
      assert_equal("http://www.example.com/exampleimage.gif", feed.images[1].url)
      assert_equal("image", feed.images[1].style)
    }
  end
  
  def test_feed_item_title
    with_feed(:from_file => 'wellformed/cdf/item_title.xml') { |feed|
      assert_equal("Example item", feed.items.first.title)
    }
  end
  
  def test_feed_item_description
    with_feed(:from_file => 'wellformed/cdf/item_abstract_map_description.xml') { |feed|
      assert_equal("Example description", feed.items.first.description)
    }
    with_feed(:from_file => 'wellformed/cdf/item_abstract_map_summary.xml') { |feed|
      assert_equal("Example description", feed.items.first.summary)
    }
  end
  
  def test_feed_item_href
    with_feed(:from_file => 'wellformed/cdf/item_href_map_link.xml') { |feed|
      assert_equal("http://www.example.org/", feed.items.first.link)
    }
  end

  def test_feed_item_links
    # TODO
  end

  def test_feed_item_images
    with_feed(:from_data => <<-FEED
      <CHANNEL>
        <ITEM HREF="http://www.example.com/item">
          <LOGO HREF="http://www.example.com/exampleicon.gif" STYLE="ICON" />
          <LOGO HREF="http://www.example.com/exampleimage.gif" STYLE="IMAGE" />
        </ITEM>
      </CHANNEL>
    FEED
    ) { |feed|
      assert_equal("http://www.example.com/item",
                   feed.items.first.link)
      assert_equal("http://www.example.com/exampleicon.gif",
                   feed.items.first.images[0].url)
      assert_equal("icon", feed.items.first.images[0].style)
      assert_equal("http://www.example.com/exampleimage.gif",
                   feed.items.first.images[1].url)
      assert_equal("image", feed.items.first.images[1].style)
    }
  end
end
