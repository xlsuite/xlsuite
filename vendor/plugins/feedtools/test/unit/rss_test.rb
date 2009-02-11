require 'test/unit'
require 'feed_tools'
require 'feed_tools/helpers/feed_tools_helper'

class RssTest < Test::Unit::TestCase
  include FeedTools::FeedToolsHelper
  
  def setup
    FeedTools.reset_configurations
    FeedTools.configurations[:tidy_enabled] = false
    FeedTools.configurations[:feed_cache] = "FeedTools::DatabaseFeedCache"
    FeedTools::FeedToolsHelper.default_local_path = 
      File.expand_path(
        File.expand_path(File.dirname(__FILE__)) + '/../feeds')
  end

  def test_feed_well_formed
    with_feed(:from_file => 'wellformed/rss/aaa_wellformed.xml') { |feed|
      assert_not_nil feed
    }
  end
  
  def test_radio_redirection
    with_feed(:from_data => <<-FEED
      <redirect>
        <newLocation>http://www.slashdot.org/index.rss</newLocation>
      </redirect>
    FEED
    ) { |feed|
      assert_not_nil feed.href
      assert_not_nil feed.title
    }
  end
  
  def test_feed_title
    with_feed(:from_file => 'wellformed/rss/channel_title.xml') { |feed|
      assert_equal("Example feed", feed.title)
    }
    with_feed(:from_file => 'wellformed/rss/channel_title_apos.xml') { |feed|
      assert_equal("Mark's title", feed.title)
    }
    with_feed(:from_file => 'wellformed/rss/channel_title_gt.xml') { |feed|
      assert_equal("2 > 1", feed.title)
    }
    with_feed(:from_file => 'wellformed/rss/channel_title_lt.xml') { |feed|
      assert_equal("1 < 2", feed.title)
    }
    with_feed(:from_file => 'wellformed/rss/channel_dc_title.xml') { |feed|
      assert_equal("Example title", feed.title)
    }
  end
  
  def test_feed_description
    with_feed(:from_file => 'wellformed/rss/channel_description.xml') { |feed|
      assert_equal(nil, feed.title)
      assert_equal("Example description", feed.description)
    }
    with_feed(:from_file => 'wellformed/rss/channel_description_escaped_markup.xml') { |feed|
      assert_equal("<p>Example description</p>", feed.description)
    }
    with_feed(:from_file => 'wellformed/rss/channel_description_map_tagline.xml') { |feed|
      assert_equal("Example description", feed.tagline)
    }
    with_feed(:from_file => 'wellformed/rss/channel_description_naked_markup.xml') { |feed|
      assert_equal("<p>Example description</p>", feed.description)
    }
    with_feed(:from_file => 'wellformed/rss/channel_description_shorttag.xml') { |feed|
      assert_equal(nil, feed.description)
      assert_equal('http://example.com/', feed.link)
    }
  end
  
  def test_feed_link
    with_feed(:from_file => 'wellformed/rss/channel_link.xml') { |feed|
      assert_equal('http://example.com/', feed.link)
    }
  end
  
  def test_feed_generator
    with_feed(:from_file => 'wellformed/rss/channel_generator.xml') { |feed|
      assert_equal("Example generator", feed.generator)
    }
  end

  def test_feed_docs
    with_feed(:from_file => 'wellformed/rss/channel_docs.xml') { |feed|
      assert_equal("http://www.example.com/", feed.docs)
    }
  end
  
  def test_feed_ttl
    with_feed(:from_file => 'wellformed/rss/channel_ttl.xml') { |feed|
      assert_equal(1.hour, feed.ttl)
    }
  end
  
  def test_feed_author
    with_feed(:from_file => 'wellformed/rss/channel_author.xml') { |feed|
      assert_equal("Example editor (me@example.com)", feed.author.raw)
      assert_equal("Example editor", feed.author.name)
      assert_equal("me@example.com", feed.author.email)
      assert_equal(nil, feed.author.url)
    }
    with_feed(:from_file => 'wellformed/rss/channel_author_map_author_detail_email_2.xml') { |feed|
      assert_equal("Example editor (me+spam@example.com)", feed.author.raw)
      assert_equal("Example editor", feed.author.name)
      assert_equal("me+spam@example.com", feed.author.email)
      assert_equal(nil, feed.author.url)
    }
    with_feed(:from_file => 'wellformed/rss/channel_author_map_author_detail_email_3.xml') { |feed|
      assert_equal("me@example.com (Example editor)", feed.author.raw)
      assert_equal("Example editor", feed.author.name)
      assert_equal("me@example.com", feed.author.email)
      assert_equal(nil, feed.author.url)
    }
    with_feed(:from_file => 'wellformed/rss/channel_dc_author.xml') { |feed|
      assert_equal("Example editor", feed.author.raw)
      assert_equal("Example editor", feed.author.name)
      assert_equal(nil, feed.author.email)
      assert_equal(nil, feed.author.url)
    }
    with_feed(:from_file => 'wellformed/rss/channel_dc_author_map_author_detail_email.xml') { |feed|
      assert_equal("Example editor (me@example.com)", feed.author.raw)
      assert_equal("Example editor", feed.author.name)
      assert_equal("me@example.com", feed.author.email)
      assert_equal(nil, feed.author.url)
    }
    with_feed(:from_file => 'wellformed/rss/channel_dc_creator.xml') { |feed|
      assert_equal("Example editor", feed.author.raw)
      assert_equal("Example editor", feed.author.name)
      assert_equal(nil, feed.author.email)
      assert_equal(nil, feed.author.url)
    }
    with_feed(:from_file => 'wellformed/rss/channel_dc_creator_map_author_detail_email.xml') { |feed|
      assert_equal("Example editor (me@example.com)", feed.author.raw)
      assert_equal("Example editor", feed.author.name)
      assert_equal("me@example.com", feed.author.email)
      assert_equal(nil, feed.author.url)
    }
    with_feed(:from_file => 'wellformed/rss/channel_managingEditor.xml') { |feed|
      assert_equal("Example editor", feed.author.raw)
      assert_equal("Example editor", feed.author.name)
      assert_equal(nil, feed.author.email)
      assert_equal(nil, feed.author.url)
    }
    with_feed(:from_file => 'wellformed/rss/channel_managingEditor_map_author_detail_email.xml') { |feed|
      assert_equal("Example editor (me@example.com)", feed.author.raw)
      assert_equal("Example editor", feed.author.name)
      assert_equal("me@example.com", feed.author.email)
      assert_equal(nil, feed.author.url)
    }
  end

  def test_feed_publisher
    with_feed(:from_file => 'wellformed/rss/channel_dc_publisher.xml') { |feed|
      assert_equal("Example editor", feed.publisher.raw)
      assert_equal("Example editor", feed.publisher.name)
      assert_equal(nil, feed.publisher.email)
      assert_equal(nil, feed.publisher.url)
    }
    with_feed(:from_file => 'wellformed/rss/channel_dc_publisher_email.xml') { |feed|
      assert_equal("Example editor (me@example.com)", feed.publisher.raw)
      assert_equal("Example editor", feed.publisher.name)
      assert_equal("me@example.com", feed.publisher.email)
      assert_equal(nil, feed.publisher.url)
    }
    with_feed(:from_file => 'wellformed/rss/channel_webMaster.xml') { |feed|
      assert_equal("Example editor", feed.publisher.raw)
      assert_equal("Example editor", feed.publisher.name)
      assert_equal(nil, feed.publisher.email)
      assert_equal(nil, feed.publisher.url)
    }
    with_feed(:from_file => 'wellformed/rss/channel_webMaster_email.xml') { |feed|
      assert_equal("Example editor (me@example.com)", feed.publisher.raw)
      assert_equal("Example editor", feed.publisher.name)
      assert_equal("me@example.com", feed.publisher.email)
      assert_equal(nil, feed.publisher.url)
    }
  end
  
  def test_feed_categories
    with_feed(:from_file => 'wellformed/rss/channel_category.xml') { |feed|
      assert_equal(1, feed.categories.size)
      assert_equal("Example category", feed.categories.first.value)
    }
    with_feed(:from_file => 'wellformed/rss/channel_category_domain.xml') { |feed|
      assert_equal(1, feed.categories.size)
      assert_equal("Example category", feed.categories.first.value)
      assert_equal("http://www.example.com/", feed.categories.first.domain)
    }
    with_feed(:from_file => 'wellformed/rss/channel_category_multiple.xml') { |feed|
      assert_equal(2, feed.categories.size)
      assert_equal("Example category 1", feed.categories[0].value)
      assert_equal("http://www.example.com/1", feed.categories[0].domain)
      assert_equal("Example category 2", feed.categories[1].value)
      assert_equal("http://www.example.com/2", feed.categories[1].domain)
    }
    with_feed(:from_file => 'wellformed/rss/channel_category_multiple_2.xml') { |feed|
      assert_equal(2, feed.categories.size)
      assert_equal("Example category 1", feed.categories[0].value)
      assert_equal(nil, feed.categories[0].domain)
      assert_equal("Example category 2", feed.categories[1].value)
      assert_equal(nil, feed.categories[1].domain)
    }
    with_feed(:from_file => 'wellformed/rss/channel_dc_subject.xml') { |feed|
      assert_equal(1, feed.categories.size)
      assert_equal("Example category", feed.categories.first.value)
    }
    with_feed(:from_file => 'wellformed/rss/channel_dc_subject_multiple.xml') { |feed|
      assert_equal(2, feed.categories.size)
      assert_equal("Example category 1", feed.categories[0].value)
      assert_equal(nil, feed.categories[0].domain)
      assert_equal("Example category 2", feed.categories[1].value)
      assert_equal(nil, feed.categories[1].domain)
    }
  end
  
  def test_feed_copyright
    with_feed(:from_file => 'wellformed/rss/channel_copyright.xml') { |feed|
      assert_equal("Example copyright", feed.copyright)
    }
    with_feed(:from_file => 'wellformed/rss/channel_dc_rights.xml') { |feed|
      assert_equal("Example copyright", feed.copyright)
    }

    # temp
    with_feed(:from_file => 'wellformed/rss/channel_dc_rights.xml') { |feed|
      assert_equal("Example copyright", feed.license)
    }
  end
  
  def test_feed_cloud
    with_feed(:from_file => 'wellformed/rss/channel_cloud_domain.xml') { |feed|
      assert_equal("rpc.sys.com", feed.cloud.domain)
      assert_equal(80, feed.cloud.port)
      assert_equal("/RPC2", feed.cloud.path)
      assert_equal("myCloud.rssPleaseNotify", feed.cloud.register_procedure)
      assert_equal("xml-rpc", feed.cloud.protocol)
    }
  end
  
  def test_feed_time_to_live
    with_feed(:from_file => 'wellformed/rss/channel_ttl.xml') { |feed|
      assert_equal(1.hour, feed.time_to_live)
    }
  end
  
  def test_feed_images
    with_feed(:from_file => 'wellformed/rss/channel_image_description.xml') { |feed|
      assert_equal("Sample image", feed.images.first.title)
      assert_equal("Available in Netscape RSS 0.91",
                   feed.images.first.description)
      assert_equal("http://example.org/url", feed.images.first.url)
      assert_equal("http://example.org/link", feed.images.first.link)
      assert_equal(80, feed.images.first.width)
      assert_equal(15, feed.images.first.height)
    }
  end
  
  def test_feed_text_input
    with_feed(:from_file => 'wellformed/rss/channel_textInput_description.xml') { |feed|
      assert_equal("Real title", feed.title)
      assert_equal("Real description", feed.description)
      assert_equal("textInput title", feed.text_input.title)
      assert_equal("textInput description", feed.text_input.description)
      assert_equal(nil, feed.text_input.link)
      assert_equal(nil, feed.text_input.name)
    }
    with_feed(:from_file => 'wellformed/rss/channel_textInput_link.xml') { |feed|
      assert_equal("http://channel.example.com/", feed.link)
      assert_equal("http://textinput.example.com/", feed.text_input.link)
      assert_equal(nil, feed.text_input.title)
      assert_equal(nil, feed.text_input.description)
      assert_equal(nil, feed.text_input.name)
    }
    with_feed(:from_file => 'wellformed/rss/channel_textInput_name.xml') { |feed|
      assert_equal("textinput name", feed.text_input.name)
      assert_equal(nil, feed.text_input.title)
      assert_equal(nil, feed.text_input.description)
      assert_equal(nil, feed.text_input.link)
    }
  end
  
  def test_item_title
    with_feed(:from_file => 'wellformed/rss/item_title.xml') { |feed|
      assert_equal("Item 1 title", feed.items.first.title)
      assert_equal(nil, feed.items.first.description)
    }
    with_feed(:from_file => 'wellformed/rss/item_dc_title.xml') { |feed|
      assert_equal("Example title", feed.items.first.title)
      assert_equal(nil, feed.items.first.description)
    }
  end

  def test_item_description
    with_feed(:from_file => 'wellformed/rss/item_description.xml') { |feed|
      assert_equal('Example description', feed.entries.first.description)
      assert_equal(nil, feed.entries.first.title)
    }
    with_feed(:from_file => 'wellformed/rss/item_description_escaped_markup.xml') { |feed|
      assert_equal('<p>Example description</p>', feed.entries.first.description)
      assert_equal(nil, feed.entries.first.title)
    }
    with_feed(:from_file => 'wellformed/rss/item_description_map_summary.xml') { |feed|
      assert_equal('Example description', feed.entries.first.description)
      assert_equal(nil, feed.entries.first.title)
    }
    with_feed(:from_file => 'wellformed/rss/item_description_naked_markup.xml') { |feed|
      assert_equal('<p>Example description</p>', feed.entries.first.description)
      assert_equal(nil, feed.entries.first.title)
    }
    with_feed(:from_file => 'wellformed/rss/item_description_not_a_doctype.xml') { |feed|
      assert_equal('&lt;!\' <a href="foo">', feed.entries.first.description)
      assert_equal(nil, feed.entries.first.title)
    }
    with_feed(:from_file => 'wellformed/rss/item_content_encoded.xml') { |feed|
      assert_equal('<p>Example content</p>', feed.entries.first.content)
      assert_equal(nil, feed.entries.first.title)
    }
    with_feed(:from_file => 'wellformed/rss/item_fullitem.xml') { |feed|
      assert_equal('<p>Example content</p>', feed.entries.first.content)
      assert_equal(nil, feed.entries.first.title)
    }
    with_feed(:from_file => 'wellformed/rss/item_xhtml_body.xml') { |feed|
      assert_equal('<p>Example content</p>', feed.entries.first.description)
      assert_equal(nil, feed.entries.first.title)
    }
  end

  def test_item_link
    with_feed(:from_file => 'wellformed/rss/item_link.xml') { |feed|
      assert_equal('http://example.com/', feed.entries.first.link)
      assert_equal(nil, feed.entries.first.title)
      assert_equal(nil, feed.entries.first.description)
    }
  end
  
  def test_item_guid
    with_feed(:from_file => 'wellformed/rss/item_guid.xml') { |feed|
      assert_equal('http://guid.example.com/', feed.entries.first.guid)
    }
    with_feed(:from_file => 'wellformed/rss/item_guid_conflict_link.xml') { |feed|
      assert_equal('http://guid.example.com/', feed.entries.first.guid)
      assert_equal('http://link.example.com/', feed.entries.first.link)
    }
    with_feed(:from_file => 'wellformed/rss/item_guid_guidislink.xml') { |feed|
      assert_equal('http://guid.example.com/', feed.entries.first.guid)
      assert_equal('http://guid.example.com/', feed.entries.first.link)
    }
    with_feed(:from_file => 'wellformed/rss/item_guid_isPermaLink_map_link.xml') { |feed|
      assert_equal('http://guid.example.com/', feed.entries.first.guid)
      assert_equal('http://guid.example.com/', feed.entries.first.link)
    }
  end
  
  def test_item_author
    with_feed(:from_file => 'wellformed/rss/item_author.xml') { |feed|
      assert_equal("Example editor", feed.items.first.author.raw)
      assert_equal("Example editor", feed.items.first.author.name)
      assert_equal(nil, feed.items.first.author.email)
      assert_equal(nil, feed.items.first.author.url)
    }
    with_feed(:from_file => 'wellformed/rss/item_author_map_author_detail_email.xml') { |feed|
      assert_equal("Example editor (me@example.com)",
                   feed.items.first.author.raw)
      assert_equal("Example editor", feed.items.first.author.name)
      assert_equal("me@example.com", feed.items.first.author.email)
      assert_equal(nil, feed.items.first.author.url)
    }
    with_feed(:from_file => 'wellformed/rss/item_dc_author.xml') { |feed|
      assert_equal("Example editor", feed.items.first.author.raw)
      assert_equal("Example editor", feed.items.first.author.name)
      assert_equal(nil, feed.items.first.author.email)
      assert_equal(nil, feed.items.first.author.url)
    }
    with_feed(:from_file => 'wellformed/rss/item_dc_author_map_author_detail_email.xml') { |feed|
      assert_equal("Example editor (me@example.com)",
                   feed.items.first.author.raw)
      assert_equal("Example editor", feed.items.first.author.name)
      assert_equal("me@example.com", feed.items.first.author.email)
      assert_equal(nil, feed.items.first.author.url)
    }
    with_feed(:from_file => 'wellformed/rss/item_dc_creator.xml') { |feed|
      assert_equal("Example editor", feed.items.first.author.raw)
      assert_equal("Example editor", feed.items.first.author.name)
      assert_equal(nil, feed.items.first.author.email)
      assert_equal(nil, feed.items.first.author.url)
    }
    with_feed(:from_file => 'wellformed/rss/item_dc_creator_map_author_detail_email.xml') { |feed|
      assert_equal("Example editor (me@example.com)",
                   feed.items.first.author.raw)
      assert_equal("Example editor", feed.items.first.author.name)
      assert_equal("me@example.com", feed.items.first.author.email)
      assert_equal(nil, feed.items.first.author.url)
    }
  end
  
  def test_item_publisher
    with_feed(:from_file => 'wellformed/rss/item_dc_publisher.xml') { |feed|
      assert_equal("Example editor", feed.items.first.publisher.raw)
      assert_equal("Example editor", feed.items.first.publisher.name)
      assert_equal(nil, feed.items.first.publisher.email)
      assert_equal(nil, feed.items.first.publisher.url)
    }
    with_feed(:from_file => 'wellformed/rss/item_dc_publisher_email.xml') { |feed|
      assert_equal("Example editor (me@example.com)", feed.items.first.publisher.raw)
      assert_equal("Example editor", feed.items.first.publisher.name)
      assert_equal("me@example.com", feed.items.first.publisher.email)
      assert_equal(nil, feed.items.first.publisher.url)
    }
  end
  
  def test_item_categories
    with_feed(:from_file => 'wellformed/rss/item_category.xml') { |feed|
      assert_equal(1, feed.items.first.categories.size)
      assert_equal("Example category", feed.items.first.categories.first.value)
    }
    with_feed(:from_file => 'wellformed/rss/item_category_domain.xml') { |feed|
      assert_equal(1, feed.items.first.categories.size)
      assert_equal("Example category", feed.items.first.categories.first.value)
      assert_equal("http://www.example.com/",
                   feed.items.first.categories.first.domain)
    }
    with_feed(:from_file => 'wellformed/rss/item_category_multiple.xml') { |feed|
      assert_equal(2, feed.items.first.categories.size)
      assert_equal("Example category 1",
                   feed.items.first.categories[0].value)
      assert_equal("http://www.example.com/1",
                   feed.items.first.categories[0].domain)
      assert_equal("Example category 2",
                   feed.items.first.categories[1].value)
      assert_equal("http://www.example.com/2",
                   feed.items.first.categories[1].domain)
    }
    with_feed(:from_file => 'wellformed/rss/item_category_multiple_2.xml') { |feed|
      assert_equal(2, feed.items.first.categories.size)
      assert_equal("Example category 1",
                   feed.items.first.categories[0].value)
      assert_equal(nil, feed.items.first.categories[0].domain)
      assert_equal("Example category 2",
                   feed.items.first.categories[1].value)
      assert_equal(nil, feed.items.first.categories[1].domain)
    }
    with_feed(:from_file => 'wellformed/rss/item_dc_subject.xml') { |feed|
      assert_equal(1, feed.items.first.categories.size)
      assert_equal("Example category", feed.items.first.categories.first.value)
    }
    with_feed(:from_file => 'wellformed/rss/item_dc_subject_multiple.xml') { |feed|
      assert_equal(2, feed.items.first.categories.size)
      assert_equal("Example category 1", feed.items.first.categories[0].value)
      assert_equal(nil, feed.items.first.categories[0].domain)
      assert_equal("Example category 2", feed.items.first.categories[1].value)
      assert_equal(nil, feed.items.first.categories[1].domain)
    }
  end
  
  def test_item_copyright
    with_feed(:from_file => 'wellformed/rss/item_dc_rights.xml') { |feed|
      assert_equal("Example copyright", feed.items.first.copyright)
    }
  end
  
  def test_item_comments
    with_feed(:from_file => 'wellformed/rss/item_comments.xml') { |feed|
      assert_equal("http://example.com/", feed.items.first.comments)
    }
  end
  
  def test_item_enclosures
    with_feed(:from_file => 'wellformed/rss/item_enclosure_length.xml') { |feed|
      assert_equal("http://example.com/", feed.items.first.link)
      assert_equal("http://example.com/",
                   feed.items.first.enclosures[0].link)
      assert_equal(100000, feed.items.first.enclosures[0].file_size)
      assert_equal("image/jpeg", feed.items.first.enclosures[0].type)
      assert_equal(nil, feed.items.first.title)
      assert_equal(nil, feed.items.first.description)
    }
    with_feed(:from_file => 'wellformed/rss/item_enclosure_multiple.xml') { |feed|
      assert_equal("http://example.com/", feed.items.first.link)
      assert_equal("http://example.com/1",
                   feed.items.first.enclosures[0].link)
      assert_equal(100000, feed.items.first.enclosures[0].file_size)
      assert_equal("image/jpeg", feed.items.first.enclosures[0].type)
      assert_equal("http://example.com/2",
                   feed.items.first.enclosures[1].link)
      assert_equal(200000, feed.items.first.enclosures[1].file_size)
      assert_equal("image/gif", feed.items.first.enclosures[1].type)
      assert_equal(nil, feed.items.first.title)
      assert_equal(nil, feed.items.first.description)
    }
  end
  
  def test_item_source
    with_feed(:from_file => 'wellformed/rss/item_source.xml') { |feed|
      assert_equal("http://example.com/", feed.items.first.source.href)
      assert_equal("Example source", feed.items.first.source.title)
    }
  end
  
  # This doesn't *really* test much since FeedTools isn't a namespace
  # aware parser yet.  Mostly it just verifies that switching namepaces
  # doesn't make the feeds unreadable.
  def test_namespaces
    with_feed(:from_file => 'wellformed/rss/rss_namespace_1.xml') { |feed|
      assert_equal("Example description", feed.description)
      assert_equal(nil, feed.title)
    }
    with_feed(:from_file => 'wellformed/rss/rss_namespace_2.xml') { |feed|
      assert_equal("Example description", feed.description)
      assert_equal(nil, feed.title)
    }
    with_feed(:from_file => 'wellformed/rss/rss_namespace_3.xml') { |feed|
      assert_equal("Example description", feed.description)
      assert_equal(nil, feed.title)
    }
    with_feed(:from_file => 'wellformed/rss/rss_namespace_4.xml') { |feed|
      assert_equal("Example description", feed.description)
      assert_equal(nil, feed.title)
    }
    with_feed(:from_file => 'wellformed/rss/rss_version_090.xml') { |feed|
      assert_equal("rss", feed.feed_type)
      assert_equal(0.9, feed.feed_version)
    }
    with_feed(:from_file => 'wellformed/rss/rss_version_091_netscape.xml') { |feed|
      assert_equal("rss", feed.feed_type)
      assert_equal(0.91, feed.feed_version)
    }
    with_feed(:from_file => 'wellformed/rss/rss_version_091_userland.xml') { |feed|
      assert_equal("rss", feed.feed_type)
      assert_equal(0.91, feed.feed_version)
    }
    with_feed(:from_file => 'wellformed/rss/rss_version_092.xml') { |feed|
      assert_equal("rss", feed.feed_type)
      assert_equal(0.92, feed.feed_version)
    }
    with_feed(:from_file => 'wellformed/rss/rss_version_093.xml') { |feed|
      assert_equal("rss", feed.feed_type)
      assert_equal(0.93, feed.feed_version)
    }
    with_feed(:from_file => 'wellformed/rss/rss_version_094.xml') { |feed|
      assert_equal("rss", feed.feed_type)
      assert_equal(0.94, feed.feed_version)
    }
    with_feed(:from_file => 'wellformed/rss/rss_version_20.xml') { |feed|
      assert_equal("rss", feed.feed_type)
      assert_equal(2.0, feed.feed_version)
    }
    with_feed(:from_file => 'wellformed/rss/rss_version_201.xml') { |feed|
      assert_equal("rss", feed.feed_type)
      assert_equal(2.0, feed.feed_version)
    }
    with_feed(:from_file => 'wellformed/rss/rss_version_21.xml') { |feed|
      assert_equal("rss", feed.feed_type)
      assert_equal(2.0, feed.feed_version)
    }
    with_feed(:from_file => 'wellformed/rss/rss_version_missing.xml') { |feed|
      assert_equal("rss", feed.feed_type)
      assert_equal(nil, feed.feed_version)
    }
  end
  
  def test_content_encoded
    with_feed(:from_data => <<-FEED
      <rss>
        <channel>
          <item>
            <title>Test Feed Title</title>
            <content:encoded
                xmlns:content="http://purl.org/rss/1.0/modules/content/">
              <![CDATA[
                Test Feed Content
              ]]>
            </content:encoded>
          </item>
        </channel>
      </rss>
    FEED
    ) { |feed|
      assert_equal("Test Feed Title", feed.items.first.title)
      assert_equal("Test Feed Content", feed.items.first.content)
    }
  end
  
  def test_item_order
    FeedTools.configurations[:timestamp_estimation_enabled] = true
    with_feed(:from_data => <<-FEED
      <rss>
        <channel>
          <item>
            <title>Item 1</title>
          </item>
          <item>
            <title>Item 2</title>
          </item>
          <item>
            <title>Item 3</title>
          </item>
        </channel>
      </rss>
    FEED
    ) { |feed|
      assert_equal("Item 1", feed.items[0].title)
      assert_equal("Item 2", feed.items[1].title)
      assert_equal("Item 3", feed.items[2].title)
    }

    with_feed(:from_data => <<-FEED
        <rss>
          <channel>
            <item>
              <title>Item 1</title>
            </item>
            <item>
              <title>Item 2</title>
              <pubDate>Thu, 13 Oct 2005 19:59:00 +0000</pubDate>
            </item>
            <item>
              <title>Item 3</title>
            </item>
          </channel>
        </rss>
      FEED
    ) { |feed|
      assert_equal("Item 1", feed.items[0].title)
      assert_equal("Item 2", feed.items[1].title)
      assert_equal("Item 3", feed.items[2].title)
    }
    
    FeedTools.configurations[:timestamp_estimation_enabled] = false
    with_feed(:from_data => <<-FEED
        <rss>
          <channel>
            <item>
              <title>Item 1</title>
            </item>
            <item>
              <title>Item 2</title>
              <pubDate>Thu, 13 Oct 2005 19:59:00 +0000</pubDate>
            </item>
            <item>
              <title>Item 3</title>
            </item>
          </channel>
        </rss>
      FEED
    ) { |feed|
      assert_equal("Item 2", feed.items[0].title)
      assert_equal(nil, feed.items[1].time)
      assert_equal(nil, feed.items[2].time)
    }
    FeedTools.configurations[:timestamp_estimation_enabled] = true
  end
  
  def test_usm
    with_feed(:from_data => <<-FEED
      <rss xmlns:atom="http://www.w3.org/2005/Atom">
        <channel>
          <title>Feed Title</title>
          <atom:link href="http://nowhere.com/feed.xml" rel="self" />
        </channel>
      </rss>
    FEED
    ) { |feed|
      assert_equal(nil, feed.link)
      assert_equal("http://nowhere.com/feed.xml", feed.url)
      assert_equal("Feed Title", feed.title)
    }
    
    with_feed(:from_data => <<-FEED
      <rss xmlns:atom="http://www.w3.org/2005/Atom">
        <channel>
          <title>Feed Title</title>
          <atom:link href="http://nowhere.com/feed.xml" rel="self" />
          <atom:link href="http://nowhere.com/"
                     type="application/xhtml+xml" />
        </channel>
      </rss>
    FEED
    ) { |feed|
      assert_equal("http://nowhere.com/", feed.link)
      assert_equal("http://nowhere.com/feed.xml", feed.url)
      assert_equal("Feed Title", feed.title)
    }
    
    with_feed(:from_data => <<-FEED
      <rss xmlns:atom="http://www.w3.org/2005/Atom">
        <channel>
          <title>Feed Title</title>
          <atom:link href="http://nowhere.com/feed.xml" rel="self" />
          <link>http://nowhere.com/</link>
        </channel>
      </rss>
    FEED
    ) { |feed|
      assert_equal("http://nowhere.com/", feed.link)
      assert_equal("http://nowhere.com/feed.xml", feed.url)
      assert_equal("Feed Title", feed.title)
    }
    
    with_feed(:from_data => <<-FEED
      <rss xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
           xmlns:admin="http://webns.net/mvcb/">
        <channel>
          <title>Feed Title</title>
          <admin:feed rdf:resource="http://nowhere.com/feed.xml" />
        </channel>
      </rss>
    FEED
    ) { |feed|
      assert_equal("http://nowhere.com/feed.xml", feed.url)
      assert_equal("Feed Title", feed.title)
    }
  end
  
  def test_http_retrieval
    # Just make sure this doesn't toss out any errors
    FeedTools::Feed.open('http://rss.slashdot.org/Slashdot/slashdot')
  end
  
  def test_blogger_line_breaks
    with_feed(:from_data => <<-FEED
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
        <channel>
          <convertLineBreaks xmlns="http://www.blogger.com/atom/ns#">
            true
          </convertLineBreaks>
          <item>
            <title>Test Item</title>
          </item>
        </channel>
      </rss>
    FEED
    ) { |feed|
      assert_equal(1, feed.items.size)
    }
  end

  def test_atom_blog_draft
    with_feed(:from_data => <<-FEED
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
        <channel>
          <draft xmlns="http://purl.org/atom-blog/ns#">false</draft>
          <item>
            <title>Test Item</title>
          </item>
        </channel>
      </rss>
    FEED
    ) { |feed|
      assert_equal(1, feed.items.size)
    }
  end
    
  def test_feed_item_description_plus_content_encoded
    with_feed(:from_data => <<-FEED
      <?xml version="1.0" encoding="iso-8859-1"?>
      <rss version="2.0">
        <channel>
          <item>
            <description>Excerpt</description>
            <content:encoded><![CDATA[Full Content]]></content:encoded>
          </item>
        </channel>
      </rss>
    FEED
    ) { |feed|
      assert_equal(1, feed.items.size)
      assert_equal("Excerpt", feed.items[0].summary)
      assert_equal("Full Content", feed.items[0].content)
    }
  end
end