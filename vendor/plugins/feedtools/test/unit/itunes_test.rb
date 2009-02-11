require 'test/unit'
require 'feed_tools'
require 'feed_tools/helpers/feed_tools_helper'

class ItunesTest < Test::Unit::TestCase
  include FeedTools::FeedToolsHelper
  
  def setup
    FeedTools.reset_configurations
    FeedTools.configurations[:tidy_enabled] = false
    FeedTools.configurations[:feed_cache] = "FeedTools::DatabaseFeedCache"
    FeedTools::FeedToolsHelper.default_local_path = 
      File.expand_path(
        File.expand_path(File.dirname(__FILE__)) + '/../feeds')
  end
  
  def test_nothing_yet
  end
end
