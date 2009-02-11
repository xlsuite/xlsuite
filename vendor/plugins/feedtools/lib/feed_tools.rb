#--
# Copyright (c) 2005 Robert Aman
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

if Object.const_defined?(:FEED_TOOLS_NAMESPACES)
  warn("FeedTools may have been loaded improperly.  This may be caused " +
    "by the presence of the RUBYOPT environment variable or by using " +
    "load instead of require.  This can also be caused by missing " +
    "the Iconv library, which is common on Windows.")
end

FEED_TOOLS_ENV = ENV['FEED_TOOLS_ENV'] ||
                 ENV['RAILS_ENV'] ||
                 'development' # :nodoc:

FEED_TOOLS_NAMESPACES = {
  "access" => "http://www.bloglines.com/about/specs/fac-1.0",
  "admin" => "http://webns.net/mvcb/",
  "ag" => "http://purl.org/rss/1.0/modules/aggregation/",
  "annotate" => "http://purl.org/rss/1.0/modules/annotate/",
  "atom10" => "http://www.w3.org/2005/Atom",
  "atom03" => "http://purl.org/atom/ns#",
  "atom-blog" => "http://purl.org/atom-blog/ns#",
  "audio" => "http://media.tangent.org/rss/1.0/",
  "bitTorrent" =>"http://www.reallysimplesyndication.com/bitTorrentRssModule",
  "blogChannel" => "http://backend.userland.com/blogChannelModule",
  "blogger" => "http://www.blogger.com/atom/ns#",
  "cc" => "http://web.resource.org/cc/",
  "creativeCommons" => "http://backend.userland.com/creativeCommonsRssModule",
  "co" => "http://purl.org/rss/1.0/modules/company",
  "content" => "http://purl.org/rss/1.0/modules/content/",
  "cp" => "http://my.theinfo.org/changed/1.0/rss/",
  "dc" => "http://purl.org/dc/elements/1.1/",
  "dcterms" => "http://purl.org/dc/terms/",
  "email" => "http://purl.org/rss/1.0/modules/email/",
  "ev" => "http://purl.org/rss/1.0/modules/event/",
  "icbm" => "http://postneo.com/icbm/",
  "image" => "http://purl.org/rss/1.0/modules/image/",
  "indexing" => "urn:atom-extension:indexing",
  "feedburner" => "http://rssnamespace.org/feedburner/ext/1.0",
  "foaf" => "http://xmlns.com/foaf/0.1/",
  "foo" => "http://hsivonen.iki.fi/FooML",
  "fm" => "http://freshmeat.net/rss/fm/",
  "gd" => "http://schemas.google.com/g/2005",
  "gr" => "http://www.google.com/schemas/reader/atom/",
  "itunes" => "http://www.itunes.com/dtds/podcast-1.0.dtd",
  "l" => "http://purl.org/rss/1.0/modules/link/",
  "media" => "http://search.yahoo.com/mrss",
  "p" => "http://purl.org/net/rss1.1/payload#",
  "pingback" => "http://madskills.com/public/xml/rss/module/pingback/",
  "prism" => "http://prismstandard.org/namespaces/1.2/basic/",
  "rdf" => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
  "rdfs" => "http://www.w3.org/2000/01/rdf-schema#",
  "ref" => "http://purl.org/rss/1.0/modules/reference/",
  "reqv" => "http://purl.org/rss/1.0/modules/richequiv/",
  "rss09" => "http://my.netscape.com/rdf/simple/0.9/",
  "rss10" => "http://purl.org/rss/1.0/",
  "rss11" => "http://purl.org/net/rss1.1#",
  "rss20" => "http://backend.userland.com/rss2",
  "search" => "http://purl.org/rss/1.0/modules/search/",
  "slash" => "http://purl.org/rss/1.0/modules/slash/",
  "soap" => "http://schemas.xmlsoap.org/soap/envelope/",
  "ss" => "http://purl.org/rss/1.0/modules/servicestatus/",
  "str" => "http://hacks.benhammersley.com/rss/streaming/",
  "sub" => "http://purl.org/rss/1.0/modules/subscription/",
  "syn" => "http://purl.org/rss/1.0/modules/syndication/",
  "taxo" => "http://purl.org/rss/1.0/modules/taxonomy/",
  "thr" => "http://purl.org/rss/1.0/modules/threading/",
  "ti" => "http://purl.org/rss/1.0/modules/textinput/",
  "trackback" => "http://madskills.com/public/xml/rss/module/trackback/",
  "wfw" => "http://wellformedweb.org/CommentAPI/",
  "wiki" => "http://purl.org/rss/1.0/modules/wiki/",
  "xhtml" => "http://www.w3.org/1999/xhtml",
  "xml" => "http://www.w3.org/XML/1998/namespace"
}

$:.unshift(File.dirname(__FILE__))
$: << (File.dirname(__FILE__) + "/feed_tools/vendor")

begin
  require 'feed_tools/version'

  begin
    require 'iconv'
  rescue Object
    warn("The Iconv library does not appear to be installed properly.  " +
      "FeedTools cannot function properly without it.")
    raise
  end

  require 'rubygems'
  require 'builder'

  # Preload optional libraries.
  begin
    require 'tidy'
  rescue Object
  end
  begin
    require 'idn'
  rescue Object
  end  

  require 'feed_tools/vendor/htree'
  require 'feed_tools/vendor/uri'

  require 'net/http'

# TODO: Not used yet, don't load since it'll only be a performance hit
#  require 'net/https'
#  require 'net/ftp'

  require 'rexml/document'

  require 'uri'
  require 'time'
  require 'cgi'
  require 'pp'
  require 'yaml'
  require 'base64'

  begin
    gem('uuidtools', '>= 0.1.2')
  rescue Gem::LoadError
    begin
      require 'uuidtools'
    rescue Object
      raise unless defined? UUID
    end
  end
  
  require 'feed_tools/monkey_patch'
  
  require 'feed_tools/feed'
  require 'feed_tools/feed_item'
  require 'feed_tools/feed_structures'
  require 'feed_tools/database_feed_cache'
  
  require 'feed_tools/helpers/html_helper'
  require 'feed_tools/helpers/xml_helper'
  require 'feed_tools/helpers/uri_helper'
rescue LoadError
  # ActiveSupport will very likely mess this up.  So drop a warn so that the
  # programmer can figure it out if things get wierd and unpredictable.
  warn("Unexpected LoadError, it is likely that you don't have one of the " +
    "libraries installed correctly.")
  raise
end

#= feed_tools.rb
#
# FeedTools was designed to be a simple XML feed parser, generator, and translator with a built-in
# caching system.
#
#== Example
#  slashdot_feed = FeedTools::Feed.open('http://www.slashdot.org/index.rss')
#  slashdot_feed.title
#  => "Slashdot"
#  slashdot_feed.description
#  => "News for nerds, stuff that matters"
#  slashdot_feed.link       
#  => "http://slashdot.org/"
#  slashdot_feed.items.first.find_node("slash:hitparade/text()").value
#  => "43,37,28,23,11,3,1"
module FeedTools
  @configurations = {}
  
  def FeedTools.load_configurations
    if @configurations.blank?
      # TODO: Load this from a config file.
      config_hash = {}
      @configurations = {
        :feed_cache => nil,
        :disable_update_from_remote => false,
        :proxy_address => nil,
        :proxy_port => nil,
        :proxy_user => nil,
        :proxy_password => nil,
        :auth_user => nil,
        :auth_password => nil,
        :auth_scheme => nil,
        :http_timeout => nil,
        :user_agent =>
          "FeedTools/#{FeedTools::FEED_TOOLS_VERSION::STRING} " + 
          "+http://www.sporkmonger.com/projects/feedtools/",
        :generator_name =>
          "FeedTools/#{FeedTools::FEED_TOOLS_VERSION::STRING}",
        :generator_href =>
          "http://www.sporkmonger.com/projects/feedtools/",
        :tidy_enabled => false,
        :tidy_options => {},
        :lazy_parsing_enabled => true,
        :serialization_enabled => false,
        :idn_enabled => true,
        :sanitization_enabled => true,
        :sanitize_with_nofollow => true,
        :always_strip_wrapper_elements => true,
        :timestamp_estimation_enabled => true,
        :url_normalization_enabled => true,
        :entry_sorting_property => "time",
        :strip_comment_count => false,
        :tab_spaces => 2,
        :max_ttl => 3.days.to_s,
        :default_ttl => 1.hour.to_s,
        :output_encoding => "utf-8"
      }.merge(config_hash)
    end
    return @configurations
  end
  
  # Resets configuration to a clean load
  def FeedTools.reset_configurations
    @configurations = nil
    FeedTools.load_configurations
  end
  
  # Returns the configuration hash for FeedTools
  def FeedTools.configurations
    if @configurations.blank?
      FeedTools.load_configurations()
    end
    return @configurations
  end
  
  # Sets the configuration hash for FeedTools
  def FeedTools.configurations=(new_configurations)
    @configurations = new_configurations
  end
  
  # Error raised when a feed cannot be retrieved    
  class FeedAccessError < StandardError
  end
  
  # Returns the current caching mechanism.
  #
  # Objects of this class must accept the following messages:
  #  id
  #  id=
  #  url
  #  url=
  #  title
  #  title=
  #  link
  #  link=
  #  feed_data
  #  feed_data=
  #  feed_data_type
  #  feed_data_type=
  #  etag
  #  etag=
  #  last_modified
  #  last_modified=
  #  save
  #
  # Additionally, the class itself must accept the following messages:
  #  find_by_id
  #  find_by_url
  #  initialize_cache
  #  connected?
  def FeedTools.feed_cache
    return nil if FeedTools.configurations[:feed_cache].blank?
    class_name = FeedTools.configurations[:feed_cache].to_s
    if @feed_cache.nil? || @feed_cache.to_s != class_name
      begin
        cache_class = eval(class_name)
        if cache_class.kind_of?(Class)
          @feed_cache = cache_class
          if @feed_cache.respond_to? :initialize_cache
            @feed_cache.initialize_cache
          end
          return cache_class
        else
          return nil
        end
      rescue
        return nil
      end
    else
      return @feed_cache
    end
  end
  
  # Returns true if FeedTools.feed_cache is not nil and a connection with
  # the cache has been successfully established.  Also returns false if an
  # error is raised while trying to determine the status of the cache.
  def FeedTools.feed_cache_connected?
    begin
      return false if FeedTools.feed_cache.nil?
      return FeedTools.feed_cache.connected?
    rescue
      return false
    end
  end    
  
  # Creates a merged "planet" feed from a set of urls.
  #
  # Options are:
  # * <tt>:multi_threaded</tt> - If set to true, feeds will
  #   be retrieved concurrently.  Not recommended when used
  #   in conjunction with the DatabaseFeedCache as it will
  #   open multiple connections to the database.
  def FeedTools.build_merged_feed(url_array, options = {})
    FeedTools::GenericHelper.validate_options([ :multi_threaded ],
                     options.keys)
    options = { :multi_threaded => false }.merge(options)
    warn("FeedTools.build_merged_feed is deprecated.")
    return nil if url_array.nil?
    merged_feed = FeedTools::Feed.new
    retrieved_feeds = []
    if options[:multi_threaded]
      feed_threads = []
      url_array.each do |feed_url|
        feed_threads << Thread.new do
          feed = Feed.open(feed_url)
          retrieved_feeds << feed
        end
      end
      feed_threads.each do |thread|
        thread.join
      end
    else
      url_array.each do |feed_url|
        feed = Feed.open(feed_url)
        retrieved_feeds << feed
      end
    end
    retrieved_feeds.each do |feed|
      merged_feed.entries = merged_feed.entries.concat(
        feed.entries.collect do |entry|
          new_entry = entry.dup
          new_entry.title = "#{feed.title}: #{entry.title}"
          new_entry
        end
      )
    end
    return merged_feed
  end
end

begin
  unless FeedTools.feed_cache.nil?
    FeedTools.feed_cache.initialize_cache
  end
rescue
end