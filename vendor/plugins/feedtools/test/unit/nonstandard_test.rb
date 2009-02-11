require 'test/unit'
require 'feed_tools'
require 'feed_tools/helpers/feed_tools_helper'

class NonStandardTest < Test::Unit::TestCase
  include FeedTools::FeedToolsHelper
  
  def setup
    FeedTools.reset_configurations
    FeedTools.configurations[:tidy_enabled] = false
    FeedTools.configurations[:feed_cache] = "FeedTools::DatabaseFeedCache"
    FeedTools::FeedToolsHelper.default_local_path = 
      File.expand_path(
        File.expand_path(File.dirname(__FILE__)) + '/../feeds')
  end
  
  def test_rss_feed_id
    with_feed(:from_data => <<-FEED
      <rss version="2.0">
        <channel>
          <guid isPermaLink="false">
            95148ACD-C1A3-45C3-A927-15C836892DCC
          </guid>
        </channel>
      </rss>
    FEED
    ) { |feed|
      assert_equal("95148ACD-C1A3-45C3-A927-15C836892DCC", feed.id)
    }
  end
  
  def test_xss_strict
    with_feed(:from_data => <<-FEED
      <?xml version="1.0" encoding="iso-8859-1"?>
      <rss version="2.0/XSS-strict">
        <channel>
          <title>tima thinking outloud.</title>
          <link>http://www.timaoutloud.org/</link>
          <description>The personal weblog of Timothy Appnel</description>
          <item>
            <link>http://www.timaoutloud.org/archives/000415.html</link>
            <title>OSCON Wrap-Up.</title>
            <description>
              It&apos;s been a week since OSCON ended and I&apos;m just
              beginning to recover. This uber post records my notes and
              personal views as a speaker and attendee.
            </description>
          </item>
          <item>
            <link>http://www.timaoutloud.org/archives/000414.html</link>
            <title>Write For The People Who Support You.</title>
            <description>
              Hooray! Mena is back. Ben too. Anil is celebrating
              6 years of blogging.
            </description>
          </item>
          <item>
            <link>http://www.timaoutloud.org/archives/000413.html</link>
            <title>tima@OSCON</title>
            <description>
              Ben Hammersley and I will be presenting 45 syndication hacks
              in 45 minutes. Will I be able to keep pace with the madness?
            </description>
          </item>
        </channel>
      </rss>
    FEED
    ) { |feed|
      assert_equal("tima thinking outloud.", feed.title)
      assert_equal("http://www.timaoutloud.org/", feed.link)
      assert_equal("The personal weblog of Timothy Appnel", feed.description)
  
      assert_equal("OSCON Wrap-Up.", feed.items[0].title)
      assert_equal("http://www.timaoutloud.org/archives/000415.html",
        feed.items[0].link)
      assert_equal(false, feed.items[0].description == nil)
  
      assert_equal("Write For The People Who Support You.", feed.items[1].title)
      assert_equal("http://www.timaoutloud.org/archives/000414.html",
        feed.items[1].link)
      assert_equal(false, feed.items[1].description == nil)
  
      assert_equal("tima@OSCON", feed.items[2].title)
      assert_equal("http://www.timaoutloud.org/archives/000413.html",
        feed.items[2].link)
      assert_equal(false, feed.items[2].description == nil)
    }
  end
  
  def test_rss_30_lite
    FeedTools.configurations[:max_ttl] = nil
    # Delusions of grandeur...
    with_feed(:from_data => <<-FEED
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="3.0" type="lite"
           source="http://www.rss3.org/files/liteSample.rss">
        <channel>
          <title>RSS Version 3</title>
          <link>http://www.rss3.org/</link>
          <description>This is a sample RSS 3 Lite-type feed</description>

          <lastBuildDate>Sun, 14 Aug 2005 09:53:59 +0000</lastBuildDate>
          <generator name="RSS3Maker">http://no.address/</generator>
          <language rel="both">en</language>
          <icon>http://www.rss3.org/files/r1.ico</icon>
          <copyright>Jonathan Avidan 2005 (c)</copyright>
          <managingEditor name="Jonathan Avidan">
            editor@rss3.org
          </managingEditor>
          <webMaster name="Jonathan Avidan">webmaster@rss3.org</webMaster>
          <ttl span="days">7</ttl>
          <docs>http://www.rss3.org/rss3lite.html</docs>
          <item>
            <title>RSS 3 Lite First Draft Now Available</title>
            <link>
              http://www.rss3.org/archive/rss3lite/first_draft.html
            </link>
            <description>
              The RSS 3 Lite-type specification first publicly
              available version
            </description>
            <pubDate>Sun, 18 Aug 2005 09:53:59 +0000</pubDate>
            <author name="Jonathan Avidan">jonathan@rss3.org</author>
            <guid type="code">6457894357689</guid>
          </item>
          <item isUpdated="true" updateNum="1">
            <title>Welcome to the RSS 3 Official Blog!</title>
            <link>http://www.rss3.org/official_blog/?p=2</link>
            <description>The RSS 3 Official Blog welcome message</description>
            <comments type="both">
              http://www.rss3.org/official_blog/?p=2#comments
            </comments>
            <pubDate>Wed, 27 Jul 2005 14:34:51 +0000</pubDate>
            <author name="Jonathan Avidan" type="writer">
              jonathan@rss3.org
            </author>
            <guid type="link">http://www.rss3.org/official_blog/?p=2</guid>
          </item>
        </channel>
      </rss>
    FEED
    ) { |feed|
      assert_equal("RSS Version 3", feed.title)
      assert_equal("http://www.rss3.org/", feed.link)
      assert_equal("This is a sample RSS 3 Lite-type feed", feed.description)
      assert_equal("http://no.address/", feed.generator)
      assert_equal("en", feed.language)
      assert_equal("http://www.rss3.org/files/r1.ico", feed.icon)
      assert_equal("Jonathan Avidan 2005 (c)", feed.copyright)
      assert_equal(7.day, feed.ttl)
      assert_equal("http://www.rss3.org/rss3lite.html", feed.docs)
      
      assert_equal("RSS 3 Lite First Draft Now Available", feed.items[0].title)
      assert_equal("http://www.rss3.org/archive/rss3lite/first_draft.html",
        feed.items[0].link)
      assert_equal(false, feed.items[0].description == nil)
      assert_equal(Time.utc(2005, "Aug", 18, 9, 53, 59), feed.items[0].time)
      assert_equal("Jonathan Avidan", feed.items[0].author.name)
      assert_equal("jonathan@rss3.org", feed.items[0].author.email)
      assert_equal("6457894357689", feed.items[0].guid)
      
      assert_equal("Welcome to the RSS 3 Official Blog!", feed.items[1].title)
      assert_equal("http://www.rss3.org/official_blog/?p=2", feed.items[1].link)
      assert_equal(false, feed.items[1].description == nil)
      assert_equal("http://www.rss3.org/official_blog/?p=2#comments",
        feed.items[1].comments)
      assert_equal(Time.utc(2005, "Jul", 27, 14, 34, 51), feed.items[1].time)
      assert_equal("Jonathan Avidan", feed.items[1].author.name)
      assert_equal("jonathan@rss3.org", feed.items[1].author.email)
      assert_equal("http://www.rss3.org/official_blog/?p=2", feed.items[1].guid)
    }
    FeedTools.configurations[:max_ttl] = 3.days.to_s
  end
end
