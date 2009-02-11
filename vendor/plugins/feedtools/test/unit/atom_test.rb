require 'test/unit'
require 'feed_tools'
require 'feed_tools/helpers/feed_tools_helper'

class AtomTest < Test::Unit::TestCase
  include FeedTools::FeedToolsHelper
  
  def setup
    FeedTools.reset_configurations
    FeedTools.configurations[:tidy_enabled] = false
    FeedTools.configurations[:feed_cache] = "FeedTools::DatabaseFeedCache"
    FeedTools::FeedToolsHelper.default_local_path = 
      File.expand_path(
        File.expand_path(File.dirname(__FILE__)) + '/../feeds')
  end

  def test_iri_feed
    if FeedTools::UriHelper.idn_enabled?
      with_feed(:from_url =>
          'http://www.詹姆斯.com/atomtests/iri/everything.atom') { |feed|
        assert_equal(
          "http://www.xn--8ws00zhy3a.com/atomtests/iri/everything.atom",
          feed.url)
      }
    end
  end
  
  def test_feed_title
    with_feed(:from_file => 'wellformed/atom/atom_namespace_1.xml') { |feed|
      assert_equal("Example Atom", feed.title)
    }
    with_feed(:from_file => 'wellformed/atom/atom_namespace_2.xml') { |feed|
      assert_equal("Example Atom", feed.title)
    }
    with_feed(:from_file => 'wellformed/atom/atom_namespace_3.xml') { |feed|
      assert_equal("Example Atom", feed.title)
    }
    with_feed(:from_file => 'wellformed/atom/atom_namespace_4.xml') { |feed|
      assert_equal("Example Atom", feed.title)
    }
    with_feed(:from_file => 'wellformed/atom/atom_namespace_5.xml') { |feed|
      assert_equal("Example Atom", feed.title)
    }
    with_feed(:from_file => 'wellformed/atom/feed_title_base64.xml') { |feed|
      assert_equal("Example &lt;b&gt;Atom&lt;/b&gt;", feed.title)
    }
    with_feed(:from_file =>
        'wellformed/atom/feed_title_base64_2.xml') { |feed|
      assert_equal(
        "&lt;p&gt;History of the &amp;lt;blink&amp;gt; tag&lt;/p&gt;",
        feed.title)
    }
  end
  
  def test_feed_link
    with_feed(:from_data => <<-FEED
      <feed version="0.3" xmlns="http://purl.org/atom/ns#">
        <link rel="alternate" href="http://www.example.com/" />
        <link rel="alternate" href="http://www.example.com/somewhere/" />
      </feed>
    FEED
    ) { |feed|
      assert_equal("http://www.example.com/", feed.link)
      assert_equal(0, feed.images.size)
    }
    with_feed(:from_data => <<-FEED
      <feed version="0.3" xmlns="http://purl.org/atom/ns#">
        <link type="text/html" href="http://www.example.com/" />
      </feed>
    FEED
    ) { |feed|
      assert_equal("http://www.example.com/", feed.link)
      assert_equal(0, feed.images.size)
    }
    with_feed(:from_data => <<-FEED
      <feed version="0.3" xmlns="http://purl.org/atom/ns#">
        <link type="application/xhtml+xml" href="http://www.example.com/" />
      </feed>
    FEED
    ) { |feed|
      assert_equal("http://www.example.com/", feed.link)
      assert_equal(0, feed.images.size)
    }
    with_feed(:from_data => <<-FEED
      <feed version="0.3" xmlns="http://purl.org/atom/ns#">
        <link href="http://www.example.com/" />
      </feed>
    FEED
    ) { |feed|
      assert_equal("http://www.example.com/", feed.link)
      assert_equal(0, feed.images.size)
    }
    with_feed(:from_data => <<-FEED
      <feed version="0.3" xmlns="http://purl.org/atom/ns#">
        <link rel="alternate" type="image/jpeg"
              href="http://www.example.com/something.jpeg" />
        <link rel="alternate" href="http://www.example.com/" />
        <link rel="alternate" type="text/html"
              href="http://www.example.com/somewhere/" />
        <link rel="alternate" type="application/xhtml+xml"
              href="http://www.example.com/xhtml/somewhere/" />
      </feed>
    FEED
    ) { |feed|
      assert_equal("http://www.example.com/xhtml/somewhere/", feed.link)
      assert_equal(1, feed.images.size)
      assert_equal("http://www.example.com/something.jpeg",
        feed.images[0].url)
    }
    with_feed(:from_data => <<-FEED
      <?xml version="1.0" encoding="utf-8"?>
      <feed xmlns="http://www.w3.org/2005/Atom"
        xmlns:thr="http://purl.org/syndication/thread/1.0">
        <link rel="self" href="http://www.intertwingly.net/blog/index.atom"/>
        <id>http://www.intertwingly.net/blog/index.atom</id>

        <title>Sam Ruby</title>
        <subtitle>It’s just data</subtitle>
        <author>
          <name>Sam Ruby</name>
          <email>rubys@intertwingly.net</email>
          <uri>.</uri>
        </author>
        <updated>2006-07-07T09:45:30-04:00</updated>
        <link href="."/>
      </feed>
    FEED
    ) { |feed|
      assert_equal(2, feed.links.size)
      assert_equal("http://www.intertwingly.net/blog/index.atom", feed.href)
      assert_equal("http://www.intertwingly.net/blog/", feed.link)
      assert_equal("http://www.intertwingly.net/blog/", feed.author.href)
    }
    with_feed(:from_data => <<-FEED
      <?xml version="1.0" encoding="utf-8"?>
      <feed xmlns="http://www.w3.org/2005/Atom"
        xmlns:thr="http://purl.org/syndication/thread/1.0">
        <link rel="self" href="http://www.intertwingly.net/blog/index.atom"/>
        <id>http://www.intertwingly.net/blog/index.atom</id>

        <title>Sam Ruby</title>
        <subtitle>It’s just data</subtitle>
        <author>
          <name>Sam Ruby</name>
          <email>rubys@intertwingly.net</email>
          <uri>.</uri>
        </author>
        <updated>2006-07-07T09:45:30-04:00</updated>
        <link href="."/>
      </feed>
    FEED
    ) { |feed|
      assert_equal(2, feed.links.size)
      assert_equal("http://www.intertwingly.net/blog/", feed.link)
      assert_equal("http://www.intertwingly.net/blog/index.atom", feed.href)
      assert_equal("http://www.intertwingly.net/blog/", feed.author.href)
    }
    with_feed(:from_data => <<-FEED
      <feed>
        <entry xml:base="http://example.com/articles/">
          <title>Pain And Suffering</title>
          <link href="1.html" type="text/plain" />
          <link href="./2.html" type="application/xml" rel="alternate" />
          <link href="../3.html" type="text/html" rel="alternate" />
          <link href="../4.html" />
          <link href="./5.html" type="application/xhtml+xml" />
          <link href="6.css" type="text/css" rel="stylesheet" />
          <content type="text">
            What does your parser come up with for the main link?
            What's the right value?
          </content>
        </entry>
      </feed>
    FEED
    ) { |feed|
      assert_equal("http://example.com/3.html", feed.entries[0].link)
    }    
    with_feed(:from_data => <<-FEED
      <?xml version="1.0" encoding="utf-8"?>
      <feed xmlns="http://www.w3.org/2005/Atom"
            xml:base="http://example.org/tests/">
      	<title>xml:base support tests</title>
      	<subtitle type="html">
      	  All alternate links should point to
      	  &lt;code>http://example.org/tests/base/result.html&lt;/code>;
      	  all links in content should point where their label says.
      	</subtitle>
      	<link href="http://example.org/tests/base/result.html"/>
      	<id>tag:plasmasturm.org,2005:Atom-Tests:xml-base</id>
      	<updated>2006-01-17T12:35:16+01:00</updated>

      	<entry>
      		<title>1: Alternate link: Absolute URL</title>
      		<link href="http://example.org/tests/base/result.html"/>
      		<id>tag:plasmasturm.org,2005:Atom-Tests:xml-base:Test1</id>
      		<updated>2006-01-17T12:35:16+01:00</updated>
      	</entry>

      	<entry>
      		<title>2: Alternate link: Host-relative absolute URL</title>
      		<link href="/tests/base/result.html"/>
      		<id>tag:plasmasturm.org,2005:Atom-Tests:xml-base:Test2</id>
      		<updated>2006-01-17T12:35:15+01:00</updated>
      	</entry>

      	<entry>
      		<title>3: Alternate link: Relative URL</title>
      		<link href="base/result.html"/>
      		<id>tag:plasmasturm.org,2005:Atom-Tests:xml-base:Test3</id>
      		<updated>2006-01-17T12:35:14+01:00</updated>
      	</entry>

      	<entry>
      		<title>
      		  4: Alternate link: Relative URL with parent directory component
      		</title>
      		<link href="../tests/base/result.html"/>
      		<id>tag:plasmasturm.org,2005:Atom-Tests:xml-base:Test4</id>
      		<updated>2006-01-17T12:35:13+01:00</updated>
      	</entry>

      	<entry>
      		<title>5: Content: Absolute URL</title>
      		<link href="http://example.org/tests/base/result.html"/>
      		<id>tag:plasmasturm.org,2005:Atom-Tests:xml-base:Test5</id>
      		<content type="html">
      		  &lt;a href="http://example.org/tests/base/result.html"&gt;
      		    http://example.org/tests/base/result.html
      		  &lt;/a&gt;
      		</content>
      		<updated>2006-01-17T12:35:12+01:00</updated>
      	</entry>

      	<entry>
      		<title>6: Content: Host-relative URL</title>
      		<link href="http://example.org/tests/base/result.html"/>
      		<id>tag:plasmasturm.org,2005:Atom-Tests:xml-base:Test6</id>
      		<content type="html">
      		  &lt;a href="/tests/base/result.html"&gt;
      		    http://example.org/tests/base/result.html
      		  &lt;/a&gt;
      		</content>
      		<updated>2006-01-17T12:35:11+01:00</updated>
      	</entry>

      	<entry>
      		<title>7: Content: Relative URL</title>
      		<link href="http://example.org/tests/base/result.html"/>
      		<id>tag:plasmasturm.org,2005:Atom-Tests:xml-base:Test7</id>
      		<content type="html">
      		  &lt;a href="base/result.html"&gt;
      		    http://example.org/tests/base/result.html
      		  &lt;/a&gt;
      		</content>
      		<updated>2006-01-17T12:35:10+01:00</updated>
      	</entry>

      	<entry>
      		<title>
      		  8: Content: Relative URL with parent directory component
      		</title>
      		<link href="http://example.org/tests/base/result.html"/>
      		<id>tag:plasmasturm.org,2005:Atom-Tests:xml-base:Test8</id>
      		<content type="html">
      		  &lt;a href="../tests/base/result.html"&gt;
      		    http://example.org/tests/base/result.html
      		  &lt;/a&gt;
      		</content>
      		<updated>2006-01-17T12:35:9+01:00</updated>
      	</entry>

      	<entry xml:base="http://example.org/tests/entrybase/">
      		<title type="html">
      		  9: Content, &lt;code>&amp;lt;entry>&lt;/code> has base:
      		  Absolute URL
      		</title>
      		<link href="http://example.org/tests/base/result.html"/>
      		<id>tag:plasmasturm.org,2005:Atom-Tests:xml-base:Test9</id>
      		<content type="html">
      		  &lt;a href="http://example.org/tests/entrybase/result.html"&gt;
      		    http://example.org/tests/entrybase/result.html
      		  &lt;/a&gt;
      		</content>
      		<updated>2006-01-17T12:35:8+01:00</updated>
      	</entry>

      	<entry xml:base="http://example.org/tests/entrybase/">
      		<title type="html">
      		  10: Content, &lt;code>&amp;lt;entry>&lt;/code> has base:
      		  Host-relative URL
      		</title>
      		<link href="http://example.org/tests/base/result.html"/>
      		<id>tag:plasmasturm.org,2005:Atom-Tests:xml-base:Test10</id>
      		<content type="html">
      		  &lt;a href="/tests/entrybase/result.html"&gt;
      		    http://example.org/tests/entrybase/result.html
      		  &lt;/a&gt;
      		</content>
      		<updated>2006-01-17T12:35:7+01:00</updated>
      	</entry>

      	<entry xml:base="http://example.org/tests/entrybase/">
      		<title type="html">
      		  11: Content, &lt;code>&amp;lt;entry>&lt;/code> has base:
      		  Relative URL
      		</title>
      		<link href="http://example.org/tests/base/result.html"/>
      		<id>tag:plasmasturm.org,2005:Atom-Tests:xml-base:Test11</id>
      		<content type="html">
      		  &lt;a href="result.html"&gt;
      		    http://example.org/tests/entrybase/result.html
      		  &lt;/a&gt;
      		</content>
      		<updated>2006-01-17T12:35:6+01:00</updated>
      	</entry>

      	<entry xml:base="http://example.org/tests/entrybase/">
      		<title type="html">
      		  12: Content, &lt;code>&amp;lt;entry>&lt;/code> has base:
      		  Relative URL with parent directory component</title>
      		<link href="http://example.org/tests/base/result.html"/>
      		<id>tag:plasmasturm.org,2005:Atom-Tests:xml-base:Test12</id>
      		<content type="html">
      		  &lt;a href="../entrybase/result.html"&gt;
      		    http://example.org/tests/entrybase/result.html
      		  &lt;/a&gt;
      		</content>
      		<updated>2006-01-17T12:35:5+01:00</updated>
      	</entry>

      	<entry>
      		<title type="html">
      		  13: Content, &lt;code>&amp;lt;content>&lt;/code> has base:
      		  Absolute URL
      		</title>
      		<link href="http://example.org/tests/base/result.html"/>
      		<id>tag:plasmasturm.org,2005:Atom-Tests:xml-base:Test13</id>
      		<content type="html"
      		         xml:base="http://example.org/tests/contentbase/">
      		  &lt;a href="http://example.org/tests/contentbase/result.html"&gt;
      		    http://example.org/tests/contentbase/result.html
      		  &lt;/a&gt;
      		</content>
      		<updated>2006-01-17T12:35:4+01:00</updated>
      	</entry>

      	<entry>
      		<title type="html">
      		  14: Content, &lt;code>&amp;lt;content>&lt;/code> has base:
      		  Host-relative URL
      		</title>
      		<link href="http://example.org/tests/base/result.html"/>
      		<id>tag:plasmasturm.org,2005:Atom-Tests:xml-base:Test14</id>
      		<content type="html"
      		         xml:base="http://example.org/tests/contentbase/">
      		  &lt;a href="/tests/contentbase/result.html"&gt;
      		    http://example.org/tests/contentbase/result.html
      		  &lt;/a&gt;
      		</content>
      		<updated>2006-01-17T12:35:3+01:00</updated>
      	</entry>

      	<entry>
      		<title type="html">
      		  15: Content, &lt;code>&amp;lt;content>&lt;/code> has base:
      		  Relative URL
      		</title>
      		<link href="http://example.org/tests/base/result.html"/>
      		<id>tag:plasmasturm.org,2005:Atom-Tests:xml-base:Test15</id>
      		<content type="html"
      		         xml:base="http://example.org/tests/contentbase/">
      		  &lt;a href="result.html"&gt;
      		    http://example.org/tests/contentbase/result.html
      		  &lt;/a&gt;
      		</content>
      		<updated>2006-01-17T12:35:2+01:00</updated>
      	</entry>

      	<entry>
      		<title type="html">
      		  16: Content, &lt;code>&amp;lt;content>&lt;/code> has base:
      		  Relative URL with parent directory component
      		</title>
      		<link href="http://example.org/tests/base/result.html"/>
      		<id>tag:plasmasturm.org,2005:Atom-Tests:xml-base:Test16</id>
      		<content type="html"
      		         xml:base="http://example.org/tests/contentbase/">
      		  &lt;a href="../contentbase/result.html"&gt;
      		    http://example.org/tests/contentbase/result.html
      		  &lt;/a&gt;
      		</content>
      		<updated>2006-01-17T12:35:1+01:00</updated>
      	</entry>

      </feed>
    FEED
    ) { |feed|
      for entry in feed.entries
        assert_equal("http://example.org/tests/base/result.html", entry.link,
          "Broken link for: " + entry.title)
      end
      assert_equal(2, feed.entries[4].content.scan(
        'http://example.org/tests/base/result.html').size)
      assert_equal(2, feed.entries[5].content.scan(
        'http://example.org/tests/base/result.html').size)
      assert_equal(2, feed.entries[6].content.scan(
        'http://example.org/tests/base/result.html').size)
      assert_equal(2, feed.entries[7].content.scan(
        'http://example.org/tests/base/result.html').size)
      assert_equal(2, feed.entries[8].content.scan(
        'http://example.org/tests/entrybase/result.html').size)
      assert_equal(2, feed.entries[9].content.scan(
        'http://example.org/tests/entrybase/result.html').size)
      assert_equal(2, feed.entries[10].content.scan(
        'http://example.org/tests/entrybase/result.html').size)
      assert_equal(2, feed.entries[11].content.scan(
        'http://example.org/tests/entrybase/result.html').size)
      assert_equal(2, feed.entries[12].content.scan(
        'http://example.org/tests/contentbase/result.html').size)
      assert_equal(2, feed.entries[13].content.scan(
        'http://example.org/tests/contentbase/result.html').size)
      assert_equal(2, feed.entries[14].content.scan(
        'http://example.org/tests/contentbase/result.html').size)
      assert_equal(2, feed.entries[15].content.scan(
        'http://example.org/tests/contentbase/result.html').size)
    }    
  end

  def test_feed_copyright
    with_feed(:from_file =>
        'wellformed/atom/feed_copyright_base64.xml') { |feed|
      assert_equal("Example &lt;b&gt;Atom&lt;/b&gt;", feed.copyright)
    }
    with_feed(:from_file =>
        'wellformed/atom/feed_copyright_base64_2.xml') { |feed|
      assert_equal(
        "&lt;p&gt;History of the &amp;lt;blink&amp;gt; tag&lt;/p&gt;",
        feed.copyright)
    }
  end
  
  def test_feed_item_author
    with_feed(:from_data => <<-FEED
      <?xml version="1.0" encoding="iso-8859-1"?>
      <feed version="0.3" xmlns="http://purl.org/atom/ns#" xml:lang="en">
        <entry>
          <author>
            <name>Cooper Baker</name>    
          </author>
        </entry>
      </feed>
    FEED
    ) { |feed|
      assert_equal(1, feed.entries.size)
      assert_equal("Cooper Baker", feed.entries[0].author.name)
    }
  end
  
  def test_feed_images
    with_feed(:from_data => <<-FEED
      <feed version="0.3" xmlns="http://purl.org/atom/ns#">
        <link type="image/jpeg" href="http://www.example.com/image.jpeg" />
      </feed>
    FEED
    ) { |feed|
      assert_equal(1, feed.images.size)
      assert_equal("http://www.example.com/image.jpeg", feed.images[0].url)
      assert_equal(nil, feed.link)
    }
  end
  
  def test_feed_item_summary_plus_content
    with_feed(:from_data => <<-FEED
      <?xml version="1.0" encoding="iso-8859-1"?>
      <prefix:feed version="1.0" xmlns:prefix="http://www.w3.org/2005/Atom">
        <prefix:entry>
          <prefix:summary>Excerpt</prefix:summary>
          <prefix:content>Full Content</prefix:content>
        </prefix:entry>
      </prefix:feed>
    FEED
    ) { |feed|
      assert_equal(1, feed.items.size)
      assert_equal("Excerpt", feed.items[0].summary)
      assert_equal("Full Content", feed.items[0].content)
    }
  end
  
  # Make sure it knows a title from a hole in the ground
  def test_all_feed_titles
    with_feed(:from_data => <<-FEED
      <?xml version="1.0" encoding="iso-8859-1"?>
      <feed version="1.0" xmlns="http://www.w3.org/2005/Atom">
        <title><![CDATA[&lt;title>]]></title>
        <entry>
          <title><![CDATA[&lt;title>]]></title>
        </entry>
      </feed>
    FEED
    ) { |feed|
      assert_equal("&amp;lt;title&gt;",
        feed.title, "Text CDATA failed")
      assert_equal(1, feed.items.size)
      assert_equal("&amp;lt;title&gt;",
        feed.items[0].title, "Text CDATA failed")
    }
    with_feed(:from_data => <<-FEED
      <?xml version="1.0" encoding="iso-8859-1"?>
      <feed version="1.0" xmlns="http://www.w3.org/2005/Atom">
        <title type="html"><![CDATA[&lt;title>]]></title>
        <entry>
          <title type="html"><![CDATA[&lt;title>]]></title>
        </entry>
      </feed>
    FEED
    ) { |feed|
      assert_equal("&lt;title&gt;",
        feed.title, "HTML CDATA failed")
      assert_equal(1, feed.items.size)
      assert_equal("&lt;title&gt;",
        feed.items[0].title, "HTML CDATA failed")
    }
    with_feed(:from_data => <<-FEED
      <?xml version="1.0" encoding="iso-8859-1"?>
      <feed version="1.0" xmlns="http://www.w3.org/2005/Atom">
        <title type="html">&amp;lt;title></title>
        <entry>
          <title type="html">&amp;lt;title></title>
        </entry>
      </feed>
    FEED
    ) { |feed|
      assert_equal("&lt;title&gt;",
        feed.title, "HTML entity failed")
      assert_equal(1, feed.items.size)
      assert_equal("&lt;title&gt;",
        feed.items[0].title, "HTML entity failed")
    }
    with_feed(:from_data => <<-FEED
      <?xml version="1.0" encoding="iso-8859-1"?>
      <feed version="1.0" xmlns="http://www.w3.org/2005/Atom">
        <title type="html">&#38;lt;title></title>
        <entry>
          <title type="html">&#38;lt;title></title>
        </entry>
      </feed>
    FEED
    ) { |feed|
      assert_equal("&lt;title&gt;",
        feed.title, "HTML NCR failed")
      assert_equal(1, feed.items.size)
      assert_equal("&lt;title&gt;",
        feed.items[0].title, "HTML NCR failed")
    }
    with_feed(:from_data => <<-FEED
      <?xml version="1.0" encoding="iso-8859-1"?>
      <feed version="1.0" xmlns="http://www.w3.org/2005/Atom">
        <title type="text"><![CDATA[<title>]]></title>
        <entry>
          <title type="text"><![CDATA[<title>]]></title>
        </entry>
      </feed>
    FEED
    ) { |feed|
      assert_equal("&lt;title&gt;",
        feed.title, "Text CDATA failed")
      assert_equal(1, feed.items.size)
      assert_equal("&lt;title&gt;",
        feed.items[0].title, "Text CDATA failed")
    }
    with_feed(:from_data => <<-FEED
      <?xml version="1.0" encoding="iso-8859-1"?>
      <feed version="1.0" xmlns="http://www.w3.org/2005/Atom">
        <title type="text">&lt;title></title>
        <entry>
          <title type="text">&lt;title></title>
        </entry>
      </feed>
    FEED
    ) { |feed|
      assert_equal("&lt;title&gt;",
        feed.title, "Text entity failed")
      assert_equal(1, feed.items.size)
      assert_equal("&lt;title&gt;",
        feed.items[0].title, "Text entity failed")
    }
    with_feed(:from_data => <<-FEED
      <?xml version="1.0" encoding="iso-8859-1"?>
      <feed version="1.0" xmlns="http://www.w3.org/2005/Atom">
        <title type="text">&#60;title></title>
        <entry>
          <title type="text">&#60;title></title>
        </entry>
      </feed>
    FEED
    ) { |feed|
      assert_equal("&lt;title&gt;",
        feed.title, "Text NCR failed")
      assert_equal(1, feed.items.size)
      assert_equal("&lt;title&gt;",
        feed.items[0].title, "Text NCR failed")
    }
    with_feed(:from_data => <<-FEED
      <?xml version="1.0" encoding="iso-8859-1"?>
      <feed version="1.0" xmlns="http://www.w3.org/2005/Atom">
        <title type="xhtml">
          <div xmlns="http://www.w3.org/1999/xhtml">&lt;title></div>
        </title>
        <entry>
          <title type="xhtml">
            <div xmlns="http://www.w3.org/1999/xhtml">&lt;title></div>
          </title>
        </entry>
      </feed>
    FEED
    ) { |feed|
      assert_equal(
        '&lt;title&gt;',
        feed.title, "XHTML entity failed")
      assert_equal(1, feed.items.size)
      assert_equal(
        '&lt;title&gt;',
        feed.items[0].title, "XHTML entity failed")
    }
    with_feed(:from_data => <<-FEED
      <?xml version="1.0" encoding="iso-8859-1"?>
      <feed version="1.0" xmlns="http://www.w3.org/2005/Atom">
        <title type="xhtml">
          <div xmlns="http://www.w3.org/1999/xhtml">&#60;title></div>
        </title>
        <entry>
          <title type="xhtml">
            <div xmlns="http://www.w3.org/1999/xhtml">&#60;title></div>
          </title>
        </entry>
      </feed>
    FEED
    ) { |feed|
      assert_equal(
        '&#60;title&gt;',
        feed.title, "XHTML NCR failed")
      assert_equal(1, feed.items.size)
      assert_equal(
        '&#60;title&gt;',
        feed.items[0].title, "XHTML NCR failed")
    }
    with_feed(:from_data => <<-FEED
      <?xml version="1.0" encoding="iso-8859-1"?>
      <feed version="1.0" xmlns="http://www.w3.org/2005/Atom">
        <title type="xhtml" xmlns:xhtml="http://www.w3.org/1999/xhtml">
          <xhtml:div>&lt;title></xhtml:div>
        </title>
        <entry>
          <title type="xhtml" xmlns:xhtml="http://www.w3.org/1999/xhtml">
            <xhtml:div>&lt;title></xhtml:div>
          </title>
        </entry>
      </feed>
    FEED
    ) { |feed|
      assert_equal(
        '&lt;title&gt;',
        feed.title, "XHTML NCR failed")
      assert_equal(1, feed.items.size)
      assert_equal(
        '&lt;title&gt;',
        feed.items[0].title, "XHTML NCR failed")
    }
  end
  
  def test_feed_item_content_sanitization
    with_feed(:from_data => <<-FEED
      <?xml version="1.0" encoding="iso-8859-1"?>
      <feed version="1.0" xmlns="http://www.w3.org/2005/Atom">
        <entry>
          <content type="xhtml" xmlns:xhtml="http://www.w3.org/1999/xhtml">
            <xhtml:div>
              <xhtml:script>alert('Content Attack Succeeded');</xhtml:script>
            </xhtml:div>
          </content>
        </entry>
      </feed>
    FEED
    ) { |feed|
      assert_equal(1, feed.items.size)
      assert_equal(
        "", feed.items[0].content, "Sanitization of content element failed")
    }
  end
end