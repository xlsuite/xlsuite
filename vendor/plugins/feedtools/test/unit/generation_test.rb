require 'test/unit'
require 'feed_tools'

class GenerationTest < Test::Unit::TestCase
  def setup
    FeedTools.reset_configurations
    FeedTools.configurations[:tidy_enabled] = false
    FeedTools.configurations[:feed_cache] = "FeedTools::DatabaseFeedCache"
  end

  def test_generate_rss_20_from_scratch
    # Create the feed
    feed = FeedTools::Feed.new
    feed.title = 'Test Feed'
    feed.description = 'Test Feed Description'
    feed.link = 'http://example.com/'
    3.times do |i|
      item = FeedTools::FeedItem.new
      item.content = "This is item number #{i}"
      item.summary = "This is the excerpt for item number #{i}"
      item.link = "http://example.com/item#{i}/"
      feed.items << item
      sleep(1.0)
    end
    output_xml = feed.build_xml('rss', 2.0)
    
    # Now read it back in
    parsed_feed = FeedTools::Feed.new
    parsed_feed.feed_data = output_xml
    parsed_feed.feed_data_type = :xml
    
    assert_equal('Test Feed', parsed_feed.title)
    assert_equal('Test Feed Description', parsed_feed.description)
    assert_equal('http://example.com/', parsed_feed.link)
    
    # Note reverse chronological order
    assert_equal('This is item number 2', parsed_feed.items[0].content)
    assert_equal('This is the excerpt for item number 2',
      parsed_feed.items[0].summary)
    assert_equal('http://example.com/item2/', parsed_feed.items[0].link)
    assert_equal('This is item number 1', parsed_feed.items[1].content)
    assert_equal('This is the excerpt for item number 1',
      parsed_feed.items[1].summary)
    assert_equal('http://example.com/item1/', parsed_feed.items[1].link)
    assert_equal('This is item number 0', parsed_feed.items[2].content)
    assert_equal('This is the excerpt for item number 0',
      parsed_feed.items[2].summary)
    assert_equal('http://example.com/item0/', parsed_feed.items[2].link)
    
    # Check feed information
    assert_equal(:xml, parsed_feed.feed_data_type)
    assert_equal('rss', parsed_feed.feed_type)
    assert_equal(2.0, parsed_feed.feed_version)
  end

  def test_generate_rss_10_from_scratch
    # Create the feed
    feed = FeedTools::Feed.new
    feed.title = 'Test Feed'
    feed.description = 'Test Feed Description'
    feed.link = 'http://example.com/'
    3.times do |i|
      item = FeedTools::FeedItem.new
      item.content = "This is item number #{i}"
      item.summary = "This is the excerpt for item number #{i}"
      item.link = "http://example.com/item#{i}/"
      feed.items << item
      sleep(0.5)
    end
    output_xml = feed.build_xml('rss', 1.0)
    
    # Now read it back in
    parsed_feed = FeedTools::Feed.new
    parsed_feed.feed_data = output_xml
    parsed_feed.feed_data_type = :xml
    
    assert_equal('Test Feed', parsed_feed.title)
    assert_equal('Test Feed Description', parsed_feed.description)
    assert_equal('http://example.com/', parsed_feed.link)
    
    # Note reverse chronological order
    assert_equal('This is item number 2', parsed_feed.items[0].content)
    assert_equal('This is the excerpt for item number 2',
      parsed_feed.items[0].summary)
    assert_equal('http://example.com/item2/', parsed_feed.items[0].link)
    assert_equal('This is item number 1', parsed_feed.items[1].content)
    assert_equal('This is the excerpt for item number 1',
      parsed_feed.items[1].summary)
    assert_equal('http://example.com/item1/', parsed_feed.items[1].link)
    assert_equal('This is item number 0', parsed_feed.items[2].content)
    assert_equal('This is the excerpt for item number 0',
      parsed_feed.items[2].summary)
    assert_equal('http://example.com/item0/', parsed_feed.items[2].link)
    
    # Check feed information
    assert_equal(:xml, parsed_feed.feed_data_type)
    assert_equal('rss', parsed_feed.feed_type)
    assert_equal(1.0, parsed_feed.feed_version)
  end
  
  def test_generate_atom_10_from_scratch
    # Create the feed
    feed = FeedTools::Feed.new
    feed.title = 'Test Feed'
    feed.description = 'Test Feed Description'
    feed.link = 'http://example.com/'
    3.times do |i|
      item = FeedTools::FeedItem.new
      item.content = "This is item number #{i}"
      item.summary = "This is the excerpt for item number #{i}"
      item.link = "http://example.com/item#{i}/"
      feed.items << item
      sleep(0.5)
    end
    output_xml = feed.build_xml('atom', 1.0)
    
    # Now read it back in
    parsed_feed = FeedTools::Feed.new
    parsed_feed.feed_data = output_xml
    parsed_feed.feed_data_type = :xml
    
    assert_equal('Test Feed', parsed_feed.title)
    assert_equal('Test Feed Description', parsed_feed.description)
    assert_equal('http://example.com/', parsed_feed.link)
    
    # Note reverse chronological order
    assert_equal('This is item number 2', parsed_feed.items[0].content)
    assert_equal('This is the excerpt for item number 2',
      parsed_feed.items[0].summary)
    assert_equal('http://example.com/item2/', parsed_feed.items[0].link)
    assert_equal('This is item number 1', parsed_feed.items[1].content)
    assert_equal('This is the excerpt for item number 1',
      parsed_feed.items[1].summary)
    assert_equal('http://example.com/item1/', parsed_feed.items[1].link)
    assert_equal('This is item number 0', parsed_feed.items[2].content)
    assert_equal('This is the excerpt for item number 0',
      parsed_feed.items[2].summary)
    assert_equal('http://example.com/item0/', parsed_feed.items[2].link)
    
    # Check feed information
    assert_equal(:xml, parsed_feed.feed_data_type)
    assert_equal('atom', parsed_feed.feed_type)
    assert_equal(1.0, parsed_feed.feed_version)
  end
  
  def test_generate_rss_with_no_content
    feed = FeedTools::Feed.new
    feed.title = 'Test Feed'
    feed.subtitle = nil
    feed.link = 'http://example.com/'
    3.times do |i|
      item = FeedTools::FeedItem.new
      item.content = nil
      item.summary = nil
      item.link = "http://example.com/item#{i}/"
      feed.items << item
      sleep(0.5)
    end
    output_xml = feed.build_xml('rss', 2.0)

    # Now read it back in
    parsed_feed = FeedTools::Feed.new
    parsed_feed.feed_data = output_xml
    parsed_feed.feed_data_type = :xml
    
    assert_equal('Test Feed', parsed_feed.title)
    assert_equal(nil, parsed_feed.description)
    assert_equal('http://example.com/', parsed_feed.link)
    
    # Note reverse chronological order
    assert_equal(nil, parsed_feed.items[0].content)
    assert_equal(nil, parsed_feed.items[0].summary)
    assert_equal('http://example.com/item2/', parsed_feed.items[0].link)
    assert_equal(nil, parsed_feed.items[1].content)
    assert_equal(nil, parsed_feed.items[1].summary)
    assert_equal('http://example.com/item1/', parsed_feed.items[1].link)
    assert_equal(nil, parsed_feed.items[2].content)
    assert_equal(nil, parsed_feed.items[2].summary)
    assert_equal('http://example.com/item0/', parsed_feed.items[2].link)
    
    # Check feed information
    assert_equal(:xml, parsed_feed.feed_data_type)
    assert_equal('rss', parsed_feed.feed_type)
    assert_equal(2.0, parsed_feed.feed_version)
  end
  
  def test_generate_rdf_with_no_content
    feed = FeedTools::Feed.new
    feed.title = 'Test Feed'
    feed.subtitle = nil
    feed.link = 'http://example.com/'
    3.times do |i|
      item = FeedTools::FeedItem.new
      item.content = nil
      item.summary = nil
      item.link = "http://example.com/item#{i}/"
      feed.items << item
      sleep(0.5)
    end
    output_xml = feed.build_xml('rss', 1.0)

    # Now read it back in
    parsed_feed = FeedTools::Feed.new
    parsed_feed.feed_data = output_xml
    parsed_feed.feed_data_type = :xml
    
    assert_equal('Test Feed', parsed_feed.title)
    assert_equal(nil, parsed_feed.description)
    assert_equal('http://example.com/', parsed_feed.link)
    
    # Note reverse chronological order
    assert_equal(nil, parsed_feed.items[0].content)
    assert_equal(nil, parsed_feed.items[0].summary)
    assert_equal('http://example.com/item2/', parsed_feed.items[0].link)
    assert_equal(nil, parsed_feed.items[1].content)
    assert_equal(nil, parsed_feed.items[1].summary)
    assert_equal('http://example.com/item1/', parsed_feed.items[1].link)
    assert_equal(nil, parsed_feed.items[2].content)
    assert_equal(nil, parsed_feed.items[2].summary)
    assert_equal('http://example.com/item0/', parsed_feed.items[2].link)
    
    # Check feed information
    assert_equal(:xml, parsed_feed.feed_data_type)
    assert_equal('rss', parsed_feed.feed_type)
    assert_equal(1.0, parsed_feed.feed_version)
  end
  
  def test_generate_atom_with_no_content
    feed = FeedTools::Feed.new
    feed.title = 'Test Feed'
    feed.subtitle = nil
    feed.link = 'http://example.com/'
    3.times do |i|
      item = FeedTools::FeedItem.new
      item.content = nil
      item.summary = nil
      item.link = "http://example.com/item#{i}/"
      feed.items << item
      sleep(0.5)
    end
    output_xml = feed.build_xml('atom', 1.0)

    # Now read it back in
    parsed_feed = FeedTools::Feed.new
    parsed_feed.feed_data = output_xml
    parsed_feed.feed_data_type = :xml
    
    assert_equal('Test Feed', parsed_feed.title)
    assert_equal(nil, parsed_feed.description)
    assert_equal('http://example.com/', parsed_feed.link)
    
    # Note reverse chronological order
    assert_equal(nil, parsed_feed.items[0].content)
    assert_equal(nil, parsed_feed.items[0].summary)
    assert_equal('http://example.com/item2/', parsed_feed.items[0].link)
    assert_equal(nil, parsed_feed.items[1].content)
    assert_equal(nil, parsed_feed.items[1].summary)
    assert_equal('http://example.com/item1/', parsed_feed.items[1].link)
    assert_equal(nil, parsed_feed.items[2].content)
    assert_equal(nil, parsed_feed.items[2].summary)
    assert_equal('http://example.com/item0/', parsed_feed.items[2].link)
    
    # Check feed information
    assert_equal(:xml, parsed_feed.feed_data_type)
    assert_equal('atom', parsed_feed.feed_type)
    assert_equal(1.0, parsed_feed.feed_version)
  end
end