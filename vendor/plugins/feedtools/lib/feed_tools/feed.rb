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

require 'rexml/document'
require 'feed_tools/feed_item'
require 'feed_tools/feed_structures'
require 'feed_tools/helpers/retrieval_helper'
require 'feed_tools/helpers/generic_helper'
require 'feed_tools/helpers/xml_helper'
require 'feed_tools/helpers/html_helper'

module FeedTools
  # The <tt>FeedTools::Feed</tt> class represents a web feed's structure.
  class Feed
    # Initialize the feed object
    def initialize
      super
      @cache_object = nil
      @http_headers = nil
      @xml_document = nil
      @feed_data = nil
      @feed_data_type = :xml
      @root_node = nil
      @channel_node = nil
      @href = nil
      @id = nil
      @title = nil
      @subtitle = nil
      @link = nil
      @last_retrieved = nil
      @time_to_live = nil
      @entries = nil
      @live = false
      @encoding = nil
      @options = nil
      @version = FeedTools::FEED_TOOLS_VERSION::STRING
    end
    
    # Breaks any references that the feed may be keeping around, thus making
    # the job of the garbage collector much, much easier.  Call this
    # method prior to feeds going out of scope to prevent memory leaks.
    def dispose()
      self.entries.each do |entry|
        entry.instance_variable_set("@root_node", nil)
        entry.instance_variable_set("@feed", nil)
        entry.instance_variable_set("@parent_feed", nil)
        entry.dispose if entry.respond_to?(:dispose)
      end
      self.entries = []
      
      @cache_object = nil
      @http_headers = nil
      @xml_document = nil
      @feed_data = nil
      @feed_data_type = nil
      @root_node = nil
      @channel_node = nil
      @href = nil
      @id = nil
      @title = nil
      @subtitle = nil
      @link = nil
      @last_retrieved = nil
      @time_to_live = nil
      @entries = nil
      @live = false
      @encoding = nil
      @options = nil

      GC.start()
      self
    end
          
    # Loads the feed specified by the url, pulling the data from the
    # cache if it hasn't expired.  Options supplied will override the
    # default options.
    def Feed.open(href, options={})
      FeedTools::GenericHelper.validate_options(
        FeedTools.configurations.keys, options.keys)

      # clean up the url
      href = FeedTools::UriHelper.normalize_url(href)

      feed_configurations = FeedTools.configurations.merge(options)
      cache_object = nil
      deserialized_feed = nil
      
      if feed_configurations[:feed_cache] != nil && FeedTools.feed_cache.nil?
        raise(ArgumentError, "There is currently no caching mechanism set. " +
          "Cannot retrieve cached feeds.")
      elsif feed_configurations[:serialization_enabled] == true
        # We've got a caching mechanism available
        cache_object = FeedTools.feed_cache.find_by_href(href)
        begin
          if cache_object != nil && cache_object.serialized != nil
            # If we've got a cache hit, deserialize
            expired = true
            if cache_object.time_to_live == nil
              cache_object.time_to_live =
                feed_configurations[:default_ttl].to_i
              cache_object.save
            end
            if (cache_object.last_retrieved == nil)
              expired = true
            elsif (cache_object.time_to_live < 30.minutes)
              expired =
                (cache_object.last_retrieved + 30.minutes) < Time.now.gmtime
            else
              expired =
                (cache_object.last_retrieved + cache_object.time_to_live) <
                  Time.now.gmtime
            end
            if !expired
              require 'yaml'
              deserialized_feed = YAML.load(cache_object.serialized)
              deserialized_feed.cache_object = cache_object
              Thread.pass
            end
          end
        rescue Exception
        end
      end
      
      if deserialized_feed == nil
        # create the new feed
        feed = FeedTools::Feed.new

        feed.configurations = feed_configurations

        # load the new feed
        feed.href = href
        if cache_object != nil
          feed.cache_object = cache_object
        end
        feed.update! unless feed.configurations[:disable_update_from_remote]
        Thread.pass
      
        return feed
      else
        return deserialized_feed
      end
    end
    
    # Returns the load options for this feed.
    def configurations
      if @configurations.blank?
        @configurations = FeedTools.configurations.dup
      end
      return @configurations
    end
    
    # Sets the load options for this feed.
    def configurations=(new_configurations)
      @configurations = new_configurations
    end

    # Loads the feed from the remote url if the feed has expired from the
    # cache or cannot be retrieved from the cache for some reason.
    def update!
      # Don't do anything if this option is set
      return if self.configurations[:disable_update_from_remote]

      if !FeedTools.feed_cache.nil? &&
          !FeedTools.feed_cache.set_up_correctly?
        FeedTools.feed_cache.initialize_cache()
      end
      if !FeedTools.feed_cache.nil? &&
          !FeedTools.feed_cache.set_up_correctly?
        raise "Your feed cache system is incorrectly set up.  " +
          "Please see the documentation for more information."
      end
      if self.http_headers.blank? && !(self.cache_object.nil?) &&
          !(self.cache_object.http_headers.nil?)
        @http_headers = YAML.load(self.cache_object.http_headers)
        @http_headers = {} unless @http_headers.kind_of? Hash
      elsif self.http_headers.blank?
        @http_headers = {}
      end
      if self.expired? == false
        @live = false
      else
        load_remote_feed!
        
        # Handle autodiscovery
        if self.http_headers['content-type'] =~ /text\/html/ ||
            self.http_headers['content-type'] =~ /application\/xhtml\+xml/

          autodiscovered_url = nil
          ['atom', 'rss', 'rdf'].each do |type|
            autodiscovered_url =
              FeedTools::HtmlHelper.extract_link_by_mime_type(self.feed_data,
                "application/#{type}+xml")
            break unless autodiscovered_url.nil?
          end
          
          if autodiscovered_url != nil
            begin
              autodiscovered_url = FeedTools::UriHelper.resolve_relative_uri(
                autodiscovered_url, [self.href])
            rescue Exception
            end
            if self.href == autodiscovered_url
              raise FeedAccessError,
                "Autodiscovery loop detected: #{autodiscovered_url}"
            end
            self.feed_data = nil
            self.href = autodiscovered_url
            if FeedTools.feed_cache.nil?
              self.cache_object = nil
            else
              self.cache_object =
                FeedTools.feed_cache.find_by_href(autodiscovered_url)
            end
            self.update!
          else
            html_body = FeedTools::XmlHelper.try_xpaths(self.xml_document, [
              "html/body"
            ])
            if html_body != nil
              raise FeedAccessError,
                "#{self.href} does not appear to be a feed."
            end
          end
        else
          ugly_redirect = FeedTools::XmlHelper.try_xpaths(self.xml_document, [
            "redirect/newLocation/text()"
          ], :select_result_value => true)
          if !ugly_redirect.blank?
            if self.href == ugly_redirect
              raise FeedAccessError,
                "Ugly redirect loop detected: #{ugly_redirect}"
            end
            self.feed_data = nil
            self.href = ugly_redirect
            if FeedTools.feed_cache.nil?
              self.cache_object = nil
            else
              self.cache_object =
                FeedTools.feed_cache.find_by_href(ugly_redirect)
            end
            self.update!
          end
        end
        
        # Reset everything that needs to be reset.
        @xml_document = nil
        @encoding_from_feed_data = nil
        @root_node = nil
        @channel_node = nil
        @id = nil
        @title = nil
        @subtitle = nil
        @copyright = nil
        @link = nil
        @time_to_live = nil
        @entries = nil
        
        if self.configurations[:lazy_parsing_enabled] == false
          self.full_parse()
        end
      end
    end
  
    # Attempts to load the feed from the remote location.  Requires the url
    # field to be set.  If an etag or the last_modified date has been set,
    # attempts to use them to prevent unnecessary reloading of identical
    # content.
    def load_remote_feed!
      @live = true
      if self.http_headers.nil? && !(self.cache_object.nil?) &&
          !(self.cache_object.http_headers.nil?)
        @http_headers = YAML.load(self.cache_object.http_headers)
      end
    
      if (self.href =~ /^feed:/) == 0
        # Woah, Nelly, how'd that happen?  You should've already been
        # corrected.  So let's fix that url.  And please,
        # just use less crappy browsers instead of badly defined
        # pseudo-protocol hacks.
        self.href = FeedTools::UriHelper.normalize_url(self.href)
      end
    
      # Find out what method we're going to be using to obtain this feed.
      begin
        uri = URI.parse(self.href)
      rescue URI::InvalidURIError
        raise FeedAccessError,
          "Cannot retrieve feed using invalid URL: " + self.href.to_s
      end
      retrieval_method = "http"
      case uri.scheme
      when "http"
        retrieval_method = "http"
      when "ftp"
        retrieval_method = "ftp"
      when "file"
        retrieval_method = "file"
      when nil
        raise FeedAccessError,
          "No protocol was specified in the url."
      else
        raise FeedAccessError,
          "Cannot retrieve feed using unrecognized protocol: " + uri.scheme
      end
    
      # No need for http headers unless we're actually doing http
      if retrieval_method == "http"
        begin
          @http_response = (FeedTools::RetrievalHelper.http_get(
            self.href, :feed_object => self) do |url, response|
              # Find out if we've already seen the url we've been
              # redirected to.
              follow_redirect = true

              begin
                cached_feed = FeedTools::Feed.open(url,
                  :disable_update_from_remote => true)
                if cached_feed.cache_object != nil &&
                    cached_feed.cache_object.new_record? != true
                  if !cached_feed.expired? &&
                      !cached_feed.http_headers.blank?
                    # Copy the cached state
                    self.href = cached_feed.href
    
                    @feed_data = cached_feed.feed_data
                    @feed_data_type = cached_feed.feed_data_type
    
                    if @feed_data.blank?
                      raise "Invalid cache data."
                    end
    
                    @title = nil; self.title
                    self.href
                    @link = nil; self.link
                  
                    self.last_retrieved = cached_feed.last_retrieved
                    self.http_headers = cached_feed.http_headers
                    self.cache_object = cached_feed.cache_object
                    @live = false
                    follow_redirect = false
                  end
                end
              rescue
                # If anything goes wrong, ignore it.
              end
              follow_redirect
            end)
          case @http_response
          when Net::HTTPSuccess
            @feed_data = self.http_response.body
            @http_headers = {}
            self.http_response.each_header do |key, value|
              self.http_headers[key.downcase] = value
            end
            self.last_retrieved = Time.now.gmtime
            @live = true
          when Net::HTTPNotModified
            @http_headers = {}
            self.http_response.each_header do |key, value|
              self.http_headers[key.downcase] = value
            end
            self.last_retrieved = Time.now.gmtime
            @live = false
          else
            @live = false
          end
        rescue Exception => error
          @live = false
          if self.feed_data.nil?
            raise error
          end
        end
      elsif retrieval_method == "https"
        # Not supported... yet
      elsif retrieval_method == "ftp"
        # Not supported... yet
        # Technically, CDF feeds are supposed to be able to be accessed
        # directly from an ftp server.  This is silly, but we'll humor
        # Microsoft.
        #
        # Eventually.  If they're lucky.  And someone demands it.
      elsif retrieval_method == "file"
        # Now that we've gone to all that trouble to ensure the url begins
        # with 'file://', strip the 'file://' off the front of the url.
        file_name = self.href.gsub(/^file:\/\//, "")
        if RUBY_PLATFORM =~ /mswin/
          file_name = file_name[1..-1] if file_name[0..0] == "/"
        end
        begin
          open(file_name) do |file|
            @http_response = nil
            @http_headers = {}
            @feed_data = file.read
            @feed_data_type = :xml
            self.last_retrieved = Time.now.gmtime
          end
        rescue
          @live = false
          # In this case, pulling from the cache is probably not going
          # to help at all, and the use should probably be immediately
          # appraised of the problem.  Raise the exception.
          raise
        end
      end
      unless self.cache_object.nil?
        begin
          self.save
        rescue
        end
      end
    end
    
    # Does a full parse of the feed.
    def full_parse
      self.href

      self.cache_object
      
      self.http_headers
      self.encoding
      self.feed_data_utf_8
      self.xml_document
      self.root_node
      self.channel_node
      
      self.base_uri
      self.feed_type
      self.feed_version

      self.entries

      self.id
      self.title
      self.subtitle
      self.links
      self.link
      self.icon
      self.favicon
      self.author
      self.publisher
      self.time
      self.updated
      self.published
      self.categories
      self.images
      self.rights
      self.time_to_live
      self.generator
      self.language

      self.docs
      self.text_input
      self.cloud

      self.itunes_summary
      self.itunes_subtitle
      self.itunes_author

      self.media_text

      self.explicit?
      
      self.entries.each do |entry|
        entry.full_parse()
      end

      nil
    end
    
    # Does a full parse, then serializes the feed object directly to the
    # cache.
    def serialize_to_cache
      @cache_object = nil
      require 'yaml'
      serialized_feed = YAML.dump(self.serializable)
      if self.cache_object != nil
        begin
          self.cache_object.serialized = serialized_feed
          self.cache_object.save
        rescue Exception
        end
      end
      return nil
    end
    
    # Returns a duplicate object suitable for serialization
    def serializable
      self.full_parse()
      entries_to_dump = self.entries
      # This prevents errors due to temporarily having feed items with
      # multiple parent feeds.
      self.entries = []
      feed_to_dump = self.dup
      feed_to_dump.instance_variable_set("@xml_document", nil)
      feed_to_dump.instance_variable_set("@root_node", nil)
      feed_to_dump.instance_variable_set("@channel_node", nil)
      feed_to_dump.entries = entries_to_dump.collect do |entry|
        entry.serializable
      end
      self.entries = entries_to_dump
      feed_to_dump.entries.each do |entry|
        entry.instance_variable_set("@root_node", nil)
      end
      return feed_to_dump
    end
        
    # Returns the relevant information from an http request.
    def http_response
      return @http_response
    end

    # Returns a hash of the http headers from the response.
    def http_headers
      if @http_headers.blank?
        if !self.cache_object.nil? && !self.cache_object.http_headers.nil?
          @http_headers = YAML.load(self.cache_object.http_headers)
          @http_headers = {} unless @http_headers.kind_of? Hash
        else
          @http_headers = {}
        end
      end
      return @http_headers
    end
    
    # Returns the encoding that the feed was parsed with
    def encoding
      if @encoding.blank?
        if !self.http_headers.blank?
          # @encoding = "utf-8"
          @encoding = self.encoding_from_feed_data
        else
          @encoding = self.encoding_from_feed_data
        end
      end
      return @encoding
    end
    
    # Returns the encoding of feed calculated only from the xml data.
    # I.e., the encoding we would come up with if we ignore RFC 3023.
    def encoding_from_feed_data
      if @encoding_from_feed_data.blank?
        raw_data = self.feed_data
        return nil if raw_data.nil?
        encoding_from_xml_instruct = 
          raw_data.scan(
            /^<\?xml [^>]*encoding="([^\"]*)"[^>]*\?>/
          ).flatten.first
        unless encoding_from_xml_instruct.blank?
          encoding_from_xml_instruct.downcase!
        end
        if encoding_from_xml_instruct.blank?
          doc = REXML::Document.new(raw_data)
          encoding_from_xml_instruct = doc.encoding.downcase
          if encoding_from_xml_instruct == "utf-8"
            # REXML has a tendency to report utf-8 overzealously, take with
            # grain of salt
            encoding_from_xml_instruct = nil
          end
        else
          @encoding_from_feed_data = encoding_from_xml_instruct
        end
        if encoding_from_xml_instruct.blank?
          sniff_table = {
            "Lo\247\224" => "ebcdic-cp-us",
            "<?xm" => "utf-8"
          }
          sniff = self.feed_data[0..3]
          if sniff_table[sniff] != nil
            @encoding_from_feed_data = sniff_table[sniff].downcase
          end
        else
          @encoding_from_feed_data = encoding_from_xml_instruct
        end
        if @encoding_from_feed_data.blank?
          # Safest assumption
          @encoding_from_feed_data = "utf-8"
        end
      end
      return @encoding_from_feed_data
    end
  
    # Returns the feed's raw data.
    def feed_data
      if @feed_data.nil?
        unless self.cache_object.nil?
          @feed_data = self.cache_object.feed_data
        end
      end
      return @feed_data
    end
  
    # Sets the feed's data.
    def feed_data=(new_feed_data)
      for var in self.instance_variables
        self.instance_variable_set(var, nil)
      end
      @http_headers = {}
      @feed_data = new_feed_data
      unless self.cache_object.nil?
        self.cache_object.feed_data = new_feed_data
      end
      ugly_redirect = FeedTools::XmlHelper.try_xpaths(self.xml_document, [
        "redirect/newLocation/text()"
      ], :select_result_value => true)
      if !ugly_redirect.blank?
        for var in self.instance_variables
          self.instance_variable_set(var, nil)
        end
        @http_headers = {}
        @feed_data = nil
        self.href = ugly_redirect
        if FeedTools.feed_cache.nil?
          self.cache_object = nil
        else
          begin
            self.cache_object =
              FeedTools.feed_cache.find_by_href(ugly_redirect)
          rescue RuntimeError => error
            if error.message =~ /sorry, too many clients already/
              warn("There are too many connections to the database open.")
            end
            raise error
          end
        end
        self.update!
      end
      
      # Get these things parsed in the correct order to avoid the retardedly
      # painful corecursion issues.
      self.href
      @links = nil
      @link = nil
      self.links
      self.link
    end
    
    # Returns the feed's raw data as utf-8.
    def feed_data_utf_8(force_encoding=nil)
      if @feed_data_utf_8.nil?
        raw_data = self.feed_data
        if force_encoding.nil?
          use_encoding = self.encoding
        else
          use_encoding = force_encoding
        end
        if use_encoding != "utf-8"
          begin
            @feed_data_utf_8 =
              Iconv.new('utf-8', use_encoding).iconv(raw_data)
          rescue
            return raw_data
          end
        else
          return self.feed_data
        end
      end
      return @feed_data_utf_8
    end
    
    # Returns the data type of the feed
    # Possible values:
    # * :xml
    # * :yaml
    # * :text
    def feed_data_type
      if @feed_data_type.nil?
        # Right now, nothing else is supported
        @feed_data_type = :xml
      end
      return @feed_data_type
    end

    # Sets the feed's data type.
    def feed_data_type=(new_feed_data_type)
      @feed_data_type = new_feed_data_type
      unless self.cache_object.nil?
        self.cache_object.feed_data_type = new_feed_data_type
      end
      if self.feed_data_type != :xml
        @xml_document = nil
      end
    end

    # Returns a REXML Document of the feed_data
    def xml_document
      if @xml_document.nil?
        return nil if self.feed_data.blank?
        if self.feed_data_type != :xml
          @xml_document = nil
        else
          begin
            @xml_document = REXML::Document.new(self.feed_data_utf_8)
          rescue Exception
            # Something failed, attempt to repair the xml with htree.
            @xml_document = HTree.parse(self.feed_data_utf_8).to_rexml
          end
        end
      end
      return @xml_document
    end
  
    # Returns the first node within the channel_node that matches the xpath
    # query.
    def find_node(xpath, select_result_value=false)
      if self.feed_data_type != :xml
        raise "The feed data type is not xml."
      end
      return FeedTools::XmlHelper.try_xpaths(self.channel_node, [xpath],
        :select_result_value => select_result_value)
    end
  
    # Returns all nodes within the channel_node that match the xpath query.
    def find_all_nodes(xpath, select_result_value=false)
      if self.feed_data_type != :xml
        raise "The feed data type is not xml."
      end
      return FeedTools::XmlHelper.try_xpaths_all(self.channel_node, [xpath],
        :select_result_value => select_result_value)
    end
  
    # Returns the root node of the feed.
    def root_node
      if @root_node.nil?
        # TODO: Fix this so that added content at the end of the file doesn't
        # break this stuff.
        # E.g.: http://smogzer.tripod.com/smog.rdf
        # ===================================================================
        begin
          if self.xml_document.nil?
            return nil
          else
            @root_node = self.xml_document.root
          end
        rescue Exception
          return nil
        end
      end
      return @root_node
    end
  
    # Returns the channel node of the feed.
    def channel_node
      if @channel_node.nil? && self.root_node != nil
        @channel_node = FeedTools::XmlHelper.try_xpaths(self.root_node, [
          "channel",
          "CHANNEL",
          "feedinfo",
          "news"
        ])
        if @channel_node == nil
          @channel_node = self.root_node
        end
      end
      return @channel_node
    end
  
    # The cache object that handles the feed persistence.
    def cache_object
      if !@href.nil? && @href =~ /^file:\/\//
        return nil
      end
      unless FeedTools.feed_cache.nil?
        if @cache_object.nil?
          begin
            if @href != nil
              begin
                @cache_object = FeedTools.feed_cache.find_by_href(@href)
              rescue RuntimeError => error
                if error.message =~ /sorry, too many clients already/
                  warn("There are too many connections to the database open.")
                  raise error
                else
                  raise error
                end
              rescue => error
                warn("The feed cache seems to be having trouble with the " +
                  "find_by_href method.  This may cause unexpected results.")
                raise error
              end
            end
            if @cache_object.nil?
              @cache_object = FeedTools.feed_cache.new
            end
          rescue
          end      
        end
      end
      return @cache_object
    end
  
    # Sets the cache object for this feed.
    #
    # This can be any object, but it must accept the following messages:
    # href
    # href=
    # title
    # title=
    # link
    # link=
    # feed_data
    # feed_data=
    # feed_data_type
    # feed_data_type=
    # etag
    # etag=
    # last_modified
    # last_modified=
    # save
    def cache_object=(new_cache_object)
      @cache_object = new_cache_object
    end
  
    # Returns the type of feed
    # Possible values:
    # "rss", "atom", "cdf", "!okay/news"
    def feed_type
      if @feed_type.nil?
        if self.root_node.nil?
          return nil
        end
        case self.root_node.name.downcase
        when "feed"
          @feed_type = "atom"
        when "rdf:rdf"
          @feed_type = "rss"
        when "rdf"
          @feed_type = "rss"
        when "rss"
          @feed_type = "rss"
        when "channel"
          if self.root_node.namespace == FEED_TOOLS_NAMESPACES['rss11']
            @feed_type = "rss"
          else
            @feed_type = "cdf"
          end
        end
      end
      return @feed_type
    end
  
    # Sets the default feed type
    def feed_type=(new_feed_type)
      @feed_type = new_feed_type
    end
  
    # Returns the version number of the feed type.
    # Intentionally does not differentiate between the Netscape and Userland
    # versions of RSS 0.91.
    def feed_version
      if @feed_version.nil?
        if self.root_node.nil?
          return nil
        end
        version = nil
        begin
          version_string = FeedTools::XmlHelper.try_xpaths(self.root_node, [
            "@version"
          ], :select_result_value => true)
          unless version_string.nil?
            version = version_string.to_f
          end
        rescue
        end
        version = nil if version == 0.0
        default_namespace = FeedTools::XmlHelper.try_xpaths(self.root_node, [
          "@xmlns"
        ], :select_result_value => true)
        case self.feed_type
        when "atom"
          if default_namespace == FEED_TOOLS_NAMESPACES['atom10']
            @feed_version = 1.0
          elsif version != nil
            @feed_version = version
          elsif default_namespace == FEED_TOOLS_NAMESPACES['atom03']
            @feed_version = 0.3
          end
        when "rss"
          if default_namespace == FEED_TOOLS_NAMESPACES['rss09']
            @feed_version = 0.9
          elsif default_namespace == FEED_TOOLS_NAMESPACES['rss10']
            @feed_version = 1.0
          elsif default_namespace == FEED_TOOLS_NAMESPACES['rss11']
            @feed_version = 1.1
          elsif version != nil
            case version
            when 2.1
              @feed_version = 2.0
            when 2.01
              @feed_version = 2.0
            else
              @feed_version = version
            end
          end
        when "cdf"
          @feed_version = 0.4
        when "!okay/news"
          @feed_version = 1.0
        end
      end
      return @feed_version
    end

    # Sets the default feed version
    def feed_version=(new_feed_version)
      @feed_version = new_feed_version
    end

    # Returns the feed's unique id
    def id
      if @id.nil?
        @id = FeedTools::XmlHelper.select_not_blank([
          FeedTools::XmlHelper.try_xpaths(self.channel_node, [
            "atom10:id/text()",
            "atom03:id/text()",
            "atom:id/text()",
            "id/text()",
            "guid/text()"
          ], :select_result_value => true),
          FeedTools::XmlHelper.try_xpaths(self.root_node, [
            "atom10:id/text()",
            "atom03:id/text()",
            "atom:id/text()",
            "id/text()",
            "guid/text()"
          ], :select_result_value => true)
        ])
      end
      return @id
    end
  
    # Sets the feed's unique id
    def id=(new_id)
      @id = new_id
    end
  
    # Returns the feed url.
    def href
      if @href_overridden != true || @href.nil?
        original_href = @href
      
        override_href = lambda do |current_href|
          begin
            if current_href.nil? && self.feed_data != nil
              # The current url is nil and we have feed data to go on
              true
            elsif current_href != nil && !(["http", "https"].include?(
                URI.parse(current_href.to_s).scheme))
              if self.feed_data != nil
                # The current url is set, but isn't a http/https url and
                # we have feed data to use to replace the current url with
                true
              else
                # The current url is set, but isn't a http/https url but
                # we don't have feed data to use to replace the current url
                # with so we'll have to wait until we do
                false
              end
            else
              # The current url is set to an http/https url and there's
              # no compelling reason to override it
              false
            end
          rescue
            # Something went wrong, so we should err on the side of caution
            # and attempt to override the url
            true
          end
        end
        if override_href.call(@href) && self.feed_data != nil
          begin
            links = FeedTools::GenericHelper.recursion_trap(:feed_href) do
              self.links
            end
            link = FeedTools::GenericHelper.recursion_trap(:feed_href) do
              self.link
            end
            if links != nil
              for link_object in links
                if link_object.rel == 'self'
                  if link_object.href != link ||
                      (link_object.href =~ /xml/ ||
                      link_object.href =~ /atom/ ||
                      link_object.href =~ /feed/)
                    @href = link_object.href
                    @href_overridden = true
                    @links = nil
                    @link = nil
                    return @href
                  end
                end
              end
            end
          rescue Exception
          end
          @links = nil
          @link = nil
          
          # rdf:about is ordered last because a lot of people put the url to
          # the feed inside it instead of a link to their blog.
          # Ordering it last gives them as many chances as humanly possible
          # for them to redeem themselves.  If the link turns out to be the
          # same as the blog link, it will be reset to the original value.
          @href = FeedTools::XmlHelper.try_xpaths(self.channel_node, [
            "admin:feed/@rdf:resource",
            "admin:feed/@resource",
            "feed/@rdf:resource",
            "feed/@resource",
            "@rdf:about",
            "@about",
            "newLocation/text()",
            "atom10:link[@rel='self']/@href"
          ], :select_result_value => true) do |result|
            override_href.call(FeedTools::UriHelper.normalize_url(result))
          end
          begin
            if !(@href =~ /^file:/) &&
                !FeedTools::UriHelper.is_uri?(@href)
              @href = FeedTools::UriHelper.resolve_relative_uri(
                @href, [self.base_uri])
            end
          rescue
          end
          if self.configurations[:url_normalization_enabled]
            @href = FeedTools::UriHelper.normalize_url(@href)
          end            
          @href.strip! unless @href.nil?
          @href = nil if @href.blank?
          @href_overridden = true
          if @href == nil
            @href = original_href
            @href_overridden = false
          end
          if @href == self.link
            @href = original_href
            @href_overridden = false
          end
          if @href_overridden == true
            @links = nil
            @link = nil
          end
        end
      end
      return @href
    end
  
    # Sets the feed url and prepares the cache_object if necessary.
    def href=(new_href)
      @href = FeedTools::UriHelper.normalize_url(new_href)
      self.cache_object.href = new_href unless self.cache_object.nil?
    end
  
    # Returns the feed title
    def title
      if @title.nil?
        repair_entities = false
        title_node = FeedTools::XmlHelper.try_xpaths(self.channel_node, [
          "atom10:title",
          "atom03:title",
          "atom:title",
          "title",
          "dc:title",
          "channelTitle",
          "TITLE"
        ])
        @title = FeedTools::HtmlHelper.process_text_construct(title_node,
          self.feed_type, self.feed_version)
        if self.feed_type == "atom" ||
            self.configurations[:always_strip_wrapper_elements]
          @title = FeedTools::HtmlHelper.strip_wrapper_element(@title)
        end
        @title = nil if @title.blank?
        self.cache_object.title = @title unless self.cache_object.nil?
      end
      return @title
    end
  
    # Sets the feed title
    def title=(new_title)
      @title = new_title
      self.cache_object.title = new_title unless self.cache_object.nil?
    end

    # Returns the feed subtitle
    def subtitle
      if @subtitle.nil?
        subtitle_node = FeedTools::XmlHelper.try_xpaths(self.channel_node, [
          "atom10:subtitle",
          "subtitle",
          "atom03:tagline",
          "tagline",
          "description",
          "summary",
          "abstract",
          "ABSTRACT",
          "content:encoded",
          "encoded",
          "content",
          "xhtml:body",
          "body",
          "xhtml:div",
          "div",
          "p:payload",
          "payload",
          "channelDescription",
          "blurb",
          "info"
        ])
        @subtitle = FeedTools::HtmlHelper.process_text_construct(
          subtitle_node, self.feed_type, self.feed_version)
        if self.feed_type == "atom" ||
            self.configurations[:always_strip_wrapper_elements]
          @subtitle = FeedTools::HtmlHelper.strip_wrapper_element(@subtitle)
        end
        if @subtitle.blank?
          @subtitle = self.itunes_summary
        end
        if @subtitle.blank?
          @subtitle = self.itunes_subtitle
        end
      end
      return @subtitle
    end

    # Sets the feed subtitle
    def subtitle=(new_subtitle)
      @subtitle = new_subtitle
    end

    # Returns the contents of the itunes:summary element
    def itunes_summary
      if @itunes_summary.nil?
        @itunes_summary = FeedTools::XmlHelper.select_not_blank([
          FeedTools::XmlHelper.try_xpaths(self.channel_node, [
            "itunes:summary/text()"
          ], :select_result_value => true),
          FeedTools::XmlHelper.try_xpaths(self.root_node, [
            "itunes:summary/text()"
          ], :select_result_value => true)
        ])
        unless @itunes_summary.blank?
          @itunes_summary =
            FeedTools::HtmlHelper.unescape_entities(@itunes_summary)
          @itunes_summary =
            FeedTools::HtmlHelper.sanitize_html(@itunes_summary)
          @itunes_summary.strip!
        else
          @itunes_summary = nil
        end
      end
      return @itunes_summary
    end

    # Sets the contents of the itunes:summary element
    def itunes_summary=(new_itunes_summary)
      @itunes_summary = new_itunes_summary
    end

    # Returns the contents of the itunes:subtitle element
    def itunes_subtitle
      if @itunes_subtitle.nil?
        @itunes_subtitle = FeedTools::XmlHelper.select_not_blank([
          FeedTools::XmlHelper.try_xpaths(self.channel_node, [
            "itunes:subtitle/text()"
          ], :select_result_value => true),
          FeedTools::XmlHelper.try_xpaths(self.root_node, [
            "itunes:subtitle/text()"
          ], :select_result_value => true)
        ])
        unless @itunes_subtitle.blank?
          @itunes_subtitle =
            FeedTools::HtmlHelper.unescape_entities(@itunes_subtitle)
          @itunes_subtitle =
            FeedTools::HtmlHelper.sanitize_html(@itunes_subtitle)
          @itunes_subtitle.strip!
        else
          @itunes_subtitle = nil
        end
      end
      return @itunes_subtitle
    end

    # Sets the contents of the itunes:subtitle element
    def itunes_subtitle=(new_itunes_subtitle)
      @itunes_subtitle = new_itunes_subtitle
    end

    # Returns the contents of the media:text element
    def media_text
      if @media_text.nil?
        @media_text = FeedTools::XmlHelper.select_not_blank([
          FeedTools::XmlHelper.try_xpaths(self.channel_node, [
            "media:text/text()"
          ], :select_result_value => true),
          FeedTools::XmlHelper.try_xpaths(self.root_node, [
            "media:text/text()"
          ], :select_result_value => true)
        ])
        unless @media_text.blank?
          @media_text = FeedTools::HtmlHelper.unescape_entities(@media_text)
          @media_text = FeedTools::HtmlHelper.sanitize_html(@media_text)
          @media_text.strip!
        else
          @media_text = nil
        end
      end
      return @media_text
    end

    # Sets the contents of the media:text element
    def media_text=(new_media_text)
      @media_text = new_media_text
    end

    # Returns the feed link
    def link
      if @link.nil?
        max_score = 0
        for link_object in self.links.reverse
          score = 0
          next if link_object.href.nil?
          if @href != nil && link_object.href == @href
            score = score - 2
          end
          if link_object.type != nil
            if (link_object.type =~ /image/ || link_object.type =~ /video/)
              score = score - 2
            end
            if FeedTools::HtmlHelper.xml_type?(link_object.type)
              score = score + 1
            end
            if FeedTools::HtmlHelper.html_type?(link_object.type)
              score = score + 2
            elsif link_object.type != nil
              score = score - 1
            end
          end
          if link_object.rel == "enclosure"
            score = score - 2
          end
          if link_object.rel == "alternate"
            score = score + 1
          end
          if link_object.rel == "self"
            score = score - 1
            if (link_object.href =~ /xml/ ||
                link_object.href =~ /atom/ ||
                link_object.href =~ /feed/)
              score = score - 1
            end
          end
          if score >= max_score
            max_score = score
            @link = link_object.href
          end
        end
        if @link.blank?
          @link = FeedTools::XmlHelper.try_xpaths(self.channel_node, [
            "@href",
            "@rdf:about",
            "@about"
          ], :select_result_value => true)
        end
        if @link.blank?
          if FeedTools::UriHelper.is_uri?(self.id) &&
              (self.id =~ /^http/)
            @link = self.id
          end
        end
        if !@link.blank?
          @link = FeedTools::HtmlHelper.unescape_entities(@link)
        end
        @link = nil if @link.blank?
        begin
          if !(@link =~ /^file:/) &&
              !FeedTools::UriHelper.is_uri?(@link)
            channel_base_uri = nil
            unless self.channel_node.nil?
              channel_base_uri = self.channel_node.base_uri
            end
            @link = FeedTools::UriHelper.resolve_relative_uri(
              @link, [channel_base_uri, self.base_uri])
          end
        rescue
        end
        if self.configurations[:url_normalization_enabled]
          @link = FeedTools::UriHelper.normalize_url(@link)
        end
        unless self.cache_object.nil?
          self.cache_object.link = @link
        end
      end
      return @link
    end

    # Sets the feed link
    def link=(new_link)
      @link = new_link
      unless self.cache_object.nil?
        self.cache_object.link = new_link
      end
    end
    
    # Returns the links collection
    def links
      if @links.blank?
        @links = []
        link_nodes =
          FeedTools::XmlHelper.combine_xpaths_all(self.channel_node, [
            "atom10:link",
            "atom03:link",
            "atom:link",
            "link",
            "channelLink",
            "a",
            "url",
            "href"
          ])
        for link_node in link_nodes
          link_object = FeedTools::Link.new
          link_object.href = FeedTools::XmlHelper.try_xpaths(link_node, [
            "@atom10:href",
            "@atom03:href",
            "@atom:href",
            "@href",
            "text()"
          ], :select_result_value => true)
          if link_object.href == "atom10:" ||
              link_object.href == "atom03:" ||
              link_object.href == "atom:"
            link_object.href = FeedTools::XmlHelper.try_xpaths(link_node, [
              "@href"
            ], :select_result_value => true)
          end
          if link_object.href.nil? && link_node.base_uri != nil
            link_object.href = ""
          end
          begin
            if !(link_object.href =~ /^file:/) &&
                !FeedTools::UriHelper.is_uri?(link_object.href)
              link_object.href = FeedTools::UriHelper.resolve_relative_uri(
                link_object.href,
                [link_node.base_uri, self.base_uri])
            end
          rescue
          end
          if self.configurations[:url_normalization_enabled]
            link_object.href =
              FeedTools::UriHelper.normalize_url(link_object.href)
          end
          link_object.href.strip! unless link_object.href.nil?
          next if link_object.href.blank?
          link_object.hreflang = FeedTools::XmlHelper.try_xpaths(link_node, [
            "@atom10:hreflang",
            "@atom03:hreflang",
            "@atom:hreflang",
            "@hreflang"
          ], :select_result_value => true)
          if link_object.hreflang == "atom10:" ||
              link_object.hreflang == "atom03:" ||
              link_object.hreflang == "atom:"
            link_object.hreflang = FeedTools::XmlHelper.try_xpaths(link_node, [
              "@hreflang"
            ], :select_result_value => true)
          end
          unless link_object.hreflang.nil?
            link_object.hreflang = link_object.hreflang.downcase
          end
          link_object.rel = FeedTools::XmlHelper.try_xpaths(link_node, [
            "@atom10:rel",
            "@atom03:rel",
            "@atom:rel",
            "@rel"
          ], :select_result_value => true)
          if link_object.rel == "atom10:" ||
              link_object.rel == "atom03:" ||
              link_object.rel == "atom:"
            link_object.rel = FeedTools::XmlHelper.try_xpaths(link_node, [
              "@rel"
            ], :select_result_value => true)
          end
          unless link_object.rel.nil?
            link_object.rel = link_object.rel.downcase
          end
          if link_object.rel.nil? && self.feed_type == "atom"
            link_object.rel = "alternate"
          end
          link_object.type = FeedTools::XmlHelper.try_xpaths(link_node, [
            "@atom10:type",
            "@atom03:type",
            "@atom:type",
            "@type"
          ], :select_result_value => true)
          if link_object.type == "atom10:" ||
              link_object.type == "atom03:" ||
              link_object.type == "atom:"
            link_object.type = FeedTools::XmlHelper.try_xpaths(link_node, [
              "@type"
            ], :select_result_value => true)
          end
          unless link_object.type.nil?
            link_object.type = link_object.type.downcase
          end
          link_object.title = FeedTools::XmlHelper.try_xpaths(link_node, [
            "@atom10:title",
            "@atom03:title",
            "@atom:title",
            "@title",
            "text()"
          ], :select_result_value => true)
          if link_object.title == "atom10:" ||
              link_object.title == "atom03:" ||
              link_object.title == "atom:"
            link_object.title = FeedTools::XmlHelper.try_xpaths(link_node, [
              "@title"
            ], :select_result_value => true)
          end
          # This catches the ambiguities between atom, rss, and cdf
          if link_object.title == link_object.href
            link_object.title = nil
          end
          link_object.length = FeedTools::XmlHelper.try_xpaths(link_node, [
            "@atom10:length",
            "@atom03:length",
            "@atom:length",
            "@length"
          ], :select_result_value => true)
          if link_object.length == "atom10:" ||
              link_object.length == "atom03:" ||
              link_object.length == "atom:"
            link_object.length = FeedTools::XmlHelper.try_xpaths(link_node, [
              "@length"
            ], :select_result_value => true)
          end
          if !link_object.length.nil?
            link_object.length = link_object.length.to_i
          else
            if !link_object.type.nil? && link_object.type[0..4] != "text" &&
                link_object.type[-3..-1] != "xml" &&
                link_object.href =~ /^http:\/\//
              # Retrieve the length with an http HEAD request
            else
              link_object.length = nil
            end
          end
          @links = [] if @links.nil?
          @links << link_object
        end
      end
      return @links
    end
    
    # Sets the links collection
    def links=(new_links)
      @links = new_links
    end
    
    # Returns the base uri for the feed, used for resolving relative paths
    def base_uri
      if @base_uri.nil?
        @base_uri = FeedTools::XmlHelper.try_xpaths(self.channel_node, [
          "@base",
          "base/@href",
          "base/text()",
          "@xml:base"
        ], :select_result_value => true)
        if @base_uri.blank?
          begin
            @base_uri =
              FeedTools::GenericHelper.recursion_trap(:feed_base_uri) do
                self.href
              end
          rescue Exception
          end
        end
        if @base_uri.blank?
          @base_uri = FeedTools::XmlHelper.try_xpaths(self.root_node, [
            "@xml:base"
          ], :select_result_value => true)
        end
        if !@base_uri.blank?
          @base_uri = FeedTools::UriHelper.normalize_url(@base_uri)
        end
        if !@base_uri.blank?
          parsed_uri = FeedTools::URI.parse(@base_uri)
          # Feedburner is almost never the base uri that was intended
          # Use the actual site instead
          if parsed_uri.host =~ /feedburner/
            site_uri =
              FeedTools::GenericHelper.recursion_trap(:feed_base_uri) do
                FeedTools::UriHelper.normalize_url(self.link)
              end
            @base_uri = site_uri if !site_uri.blank?
          end
        end
      end
      return @base_uri
    end
            
    # Sets the base uri for the feed
    def base_uri=(new_base_uri)
      @base_uri = new_base_uri
    end

    # Returns the url to the icon file for this feed.
    def icon
      if @icon.nil?
        icon_node = FeedTools::XmlHelper.try_xpaths(self.channel_node, [
          "link[@rel='icon']",
          "link[@rel='shortcut icon']",
          "link[@type='image/x-icon']",
          "icon",
          "logo[@style='icon']",
          "LOGO[@STYLE='ICON']"
        ])
        unless icon_node.nil?
          @icon = FeedTools::XmlHelper.try_xpaths(icon_node, [
            "@atom10:href",
            "@atom03:href",
            "@atom:href",
            "@href",
            "text()"
          ], :select_result_value => true)
          begin
            if !(@icon =~ /^file:/) &&
                !FeedTools::UriHelper.is_uri?(@icon)
              channel_base_uri = nil
              unless self.channel_node.nil?
                channel_base_uri = self.channel_node.base_uri
              end
              @icon = FeedTools::UriHelper.resolve_relative_uri(
                @icon, [channel_base_uri, self.base_uri])
            end
          rescue
          end
          @icon = nil unless FeedTools::UriHelper.is_uri?(@icon)
          @icon = nil if @icon.blank?
        end
      end
      return @icon
    end
    
    # Returns the favicon url for this feed.
    # This method first tries to use the url from the link field instead of
    # the feed url, in order to avoid grabbing the favicon for services like
    # feedburner.
    def favicon
      if @favicon.nil?
        if !self.link.blank?
          begin
            link_uri = URI.parse(
              FeedTools::UriHelper.normalize_url(self.link))
            if link_uri.scheme == "http"
              @favicon =
                "http://" + link_uri.host + "/favicon.ico"
            end
          rescue
            @favicon = nil
          end
          if @favicon.nil? && !self.href.blank?
            begin
              feed_uri = URI.parse(
                FeedTools::UriHelper.normalize_url(self.href))
              if feed_uri.scheme == "http"
                @favicon =
                  "http://" + feed_uri.host + "/favicon.ico"
              end
            rescue
              @favicon = nil
            end
          end
        else
          @favicon = nil
        end
      end
      return @favicon
    end

    # Returns the feed author
    def author
      if @author.nil?
        @author = FeedTools::Author.new
        author_node = FeedTools::XmlHelper.try_xpaths(self.channel_node, [
          "atom10:author",
          "atom03:author",
          "atom:author",
          "author",
          "managingEditor",
          "dc:author",
          "dc:creator"
        ])
        unless author_node.nil?
          @author.raw = FeedTools::XmlHelper.try_xpaths(
            author_node, ["text()"], :select_result_value => true)
          @author.raw = FeedTools::HtmlHelper.unescape_entities(@author.raw)
          unless @author.raw.nil?
            raw_scan = @author.raw.scan(
              /(.*)\((\b[A-Z0-9._%-\+]+@[A-Z0-9._%-]+\.[A-Z]{2,4}\b)\)/i)
            if raw_scan.nil? || raw_scan.size == 0
              raw_scan = @author.raw.scan(
                /(\b[A-Z0-9._%-\+]+@[A-Z0-9._%-]+\.[A-Z]{2,4}\b)\s*\((.*)\)/i)
              unless raw_scan.size == 0
                author_raw_pair = raw_scan.first.reverse
              end
            else
              author_raw_pair = raw_scan.first
            end
            if raw_scan.nil? || raw_scan.size == 0
              email_scan = @author.raw.scan(
                /\b[A-Z0-9._%-\+]+@[A-Z0-9._%-]+\.[A-Z]{2,4}\b/i)
              if email_scan != nil && email_scan.size > 0
                @author.email = email_scan.first.strip
              end
            end
            unless author_raw_pair.nil? || author_raw_pair.size == 0
              @author.name = author_raw_pair.first.strip
              @author.email = author_raw_pair.last.strip
            else
              unless @author.raw.include?("@")
                # We can be reasonably sure we are looking at something
                # that the creator didn't intend to contain an email address
                # if it got through the preceeding regexes and it doesn't
                # contain the tell-tale '@' symbol.
                @author.name = @author.raw
              end
            end
          end
          if @author.name.blank?
            @author.name = FeedTools::HtmlHelper.unescape_entities(
              FeedTools::XmlHelper.try_xpaths(author_node, [
                "atom10:name/text()",
                "atom03:name/text()",
                "atom:name/text()",
                "name/text()",
                "@name"
              ], :select_result_value => true)
            )
          end
          if @author.email.blank?
            @author.email = FeedTools::HtmlHelper.unescape_entities(
              FeedTools::XmlHelper.try_xpaths(author_node, [
                "atom10:email/text()",
                "atom03:email/text()",
                "atom:email/text()",
                "email/text()",
                "@email"
              ], :select_result_value => true)
            )
          end
          if @author.url.blank?
            @author.url = FeedTools::HtmlHelper.unescape_entities(
              FeedTools::XmlHelper.try_xpaths(author_node, [
                "atom10:url/text()",
                "atom03:url/text()",
                "atom:url/text()",
                "url/text()",
                "atom10:uri/text()",
                "atom03:uri/text()",
                "atom:uri/text()",
                "uri/text()",
                "@href",
                "@uri",
                "@href"
              ], :select_result_value => true)
            )
          end
          if @author.name.blank? && !@author.raw.blank? &&
              !@author.email.blank?
            name_scan = @author.raw.scan(
              /"?([^"]*)"? ?[\(<].*#{@author.email}.*[\)>].*/)
            if name_scan.flatten.size == 1
              @author.name = name_scan.flatten[0].strip
            end
            if @author.name.blank?
              name_scan = @author.raw.scan(
                /.*#{@author.email} ?[\(<]"?([^"]*)"?[\)>].*/)
              if name_scan.flatten.size == 1
                @author.name = name_scan.flatten[0].strip
              end
            end
          end
          @author.name = nil if @author.name.blank?
          @author.raw = nil if @author.raw.blank?
          @author.email = nil if @author.email.blank?
          @author.url = nil if @author.url.blank?
          if @author.url != nil
            begin
              if !(@author.url =~ /^file:/) &&
                  !FeedTools::UriHelper.is_uri?(@author.url)
                @author.url = FeedTools::UriHelper.resolve_relative_uri(
                  @author.url, [author_node.base_uri, self.base_uri])
              end
            rescue
            end
          end
          if FeedTools::XmlHelper.try_xpaths(author_node,
              ["@gr:unknown-author"], :select_result_value => true) == "true"
            if @author.name == "(author unknown)"
              @author.name = nil
            end
          end
        end
        # Fallback on the itunes module if we didn't find an author name
        begin
          @author.name = self.itunes_author if @author.name.nil?
        rescue
          @author.name = nil
        end
      end
      return @author
    end

    # Sets the feed author
    def author=(new_author)
      if new_author.respond_to?(:name) &&
          new_author.respond_to?(:email) &&
          new_author.respond_to?(:url)
        # It's a complete author object, just set it.
        @author = new_author
      else
        # We're not looking at an author object, this is probably a string,
        # default to setting the author's name.
        if @author.nil?
          @author = FeedTools::Author.new
        end
        @author.name = new_author
      end
    end

    # Returns the feed publisher
    def publisher
      if @publisher.nil?
        @publisher = FeedTools::Author.new
        @publisher.raw = FeedTools::HtmlHelper.unescape_entities(        
          FeedTools::XmlHelper.try_xpaths(self.channel_node, [
            "webMaster/text()",
            "dc:publisher/text()"
          ], :select_result_value => true))

        unless @publisher.raw.blank?
          raw_scan = @publisher.raw.scan(
            /(.*)\((\b[A-Z0-9._%-\+]+@[A-Z0-9._%-]+\.[A-Z]{2,4}\b)\)/i)
          if raw_scan.nil? || raw_scan.size == 0
            raw_scan = @publisher.raw.scan(
              /(\b[A-Z0-9._%-\+]+@[A-Z0-9._%-]+\.[A-Z]{2,4}\b)\s*\((.*)\)/i)
            unless raw_scan.size == 0
              publisher_raw_pair = raw_scan.first.reverse
            end
          else
            publisher_raw_pair = raw_scan.first
          end
          if raw_scan.nil? || raw_scan.size == 0
            email_scan = @publisher.raw.scan(
              /\b[A-Z0-9._%-\+]+@[A-Z0-9._%-]+\.[A-Z]{2,4}\b/i)
            if email_scan != nil && email_scan.size > 0
              @publisher.email = email_scan.first.strip
            end
          end
          unless publisher_raw_pair.nil? || publisher_raw_pair.size == 0
            @publisher.name = publisher_raw_pair.first.strip
            @publisher.email = publisher_raw_pair.last.strip
          else
            unless @publisher.raw.include?("@")
              # We can be reasonably sure we are looking at something
              # that the creator didn't intend to contain an email address if
              # it got through the preceeding regexes and it doesn't
              # contain the tell-tale '@' symbol.
              @publisher.name = @publisher.raw
            end
          end
        end

        @publisher.name = nil if @publisher.name.blank?
        @publisher.raw = nil if @publisher.raw.blank?
        @publisher.email = nil if @publisher.email.blank?
        @publisher.url = nil if @publisher.url.blank?
        if @publisher.url != nil
          begin
            if !(@publisher.url =~ /^file:/) &&
                !FeedTools::UriHelper.is_uri?(@publisher.url)
              channel_base_uri = nil
              unless self.channel_node.nil?
                channel_base_uri = self.channel_node.base_uri
              end
              @publisher.url = FeedTools::UriHelper.resolve_relative_uri(
                @publisher.url, [channel_base_uri, self.base_uri])
            end
          rescue
          end
        end        
      end
      return @publisher
    end

    # Sets the feed publisher
    def publisher=(new_publisher)
      if new_publisher.respond_to?(:name) &&
          new_publisher.respond_to?(:email) &&
          new_publisher.respond_to?(:url)
        # It's a complete Author object, just set it.
        @publisher = new_publisher
      else
        # We're not looking at an Author object, this is probably a string,
        # default to setting the publisher's name.
        if @publisher.nil?
          @publisher = FeedTools::Author.new
        end
        @publisher.name = new_publisher
      end
    end
  
    # Returns the contents of the itunes:author element
    #
    # Returns any incorrectly placed channel-level itunes:author
    # elements.  They're actually amazingly common.  People don't read specs.
    # There is no setter for this, since this is an incorrectly placed
    # attribute.
    def itunes_author
      if @itunes_author.nil?
        @itunes_author = FeedTools::HtmlHelper.unescape_entities(
          FeedTools::XmlHelper.try_xpaths(self.channel_node, [
            "itunes:author/text()"
          ], :select_result_value => true)
        )
        @itunes_author = nil if @itunes_author.blank?
      end
      return @itunes_author
    end

    # Returns the feed time
    def time
      if @time.nil?
        time_string = FeedTools::XmlHelper.try_xpaths(self.channel_node, [
          "atom10:updated/text()",
          "atom03:updated/text()",
          "atom:updated/text()",
          "updated/text()",
          "atom10:modified/text()",
          "atom03:modified/text()",
          "atom:modified/text()",
          "modified/text()",
          "time/text()",
          "lastBuildDate/text()",
          "atom10:issued/text()",
          "atom03:issued/text()",
          "atom:issued/text()",
          "issued/text()",
          "atom10:published/text()",
          "atom03:published/text()",
          "atom:published/text()",
          "published/text()",
          "dc:date/text()",
          "pubDate/text()",
          "date/text()"
        ], :select_result_value => true)
        begin
          unless time_string.blank?
            @time = Time.parse(time_string).gmtime
          else
            if self.configurations[:timestamp_estimation_enabled]
              @time = Time.now.gmtime
            end
          end
        rescue
          if self.configurations[:timestamp_estimation_enabled]
            @time = Time.now.gmtime
          end
        end
      end
      return @time
    end
  
    # Sets the feed time
    def time=(new_time)
      @time = new_time
    end
  
    # Returns the feed updated time
    def updated
      if @updated.nil?
        updated_string = FeedTools::XmlHelper.try_xpaths(self.channel_node, [
          "atom10:updated/text()",
          "atom03:updated/text()",
          "atom:updated/text()",
          "updated/text()",
          "atom10:modified/text()",
          "atom03:modified/text()",
          "atom:modified/text()",
          "modified/text()",
          "lastBuildDate/text()"
        ], :select_result_value => true)
        unless updated_string.blank?
          @updated = Time.parse(updated_string).gmtime rescue nil
        else
          @updated = nil
        end
      end
      return @updated
    end
  
    # Sets the feed updated time
    def updated=(new_updated)
      @updated = new_updated
    end

    # Returns the feed published time
    def published
      if @published.nil?
        published_string =
          FeedTools::XmlHelper.try_xpaths(self.channel_node, [
            "atom10:published/text()",
            "atom03:published/text()",
            "atom:published/text()",
            "published/text()",
            "dc:date/text()",
            "pubDate/text()",
            "atom10:issued/text()",
            "atom03:issued/text()",
            "atom:issued/text()",
            "issued/text()"
          ], :select_result_value => true)
        unless published_string.blank?
          @published = Time.parse(published_string).gmtime rescue nil
        else
          @published = nil
        end
      end
      return @published
    end
  
    # Sets the feed published time
    def published=(new_published)
      @published = new_published
    end

    # Returns a list of the feed's categories
    def categories
      if @categories.nil?
        @categories = []
        category_nodes =
          FeedTools::XmlHelper.try_xpaths_all(self.channel_node, [
            "category",
            "dc:subject"
          ])
        unless category_nodes.nil?
          for category_node in category_nodes
            category = FeedTools::Category.new
            category.term = FeedTools::XmlHelper.try_xpaths(category_node, [
              "@term",
              "text()"
            ], :select_result_value => true)
            category.term.strip! unless category.term.blank?
            category.label = FeedTools::XmlHelper.try_xpaths(
              category_node, ["@label"],
              :select_result_value => true)
            category.label.strip! unless category.label.blank?
            category.scheme = FeedTools::XmlHelper.try_xpaths(category_node, [
              "@scheme",
              "@domain"
            ], :select_result_value => true)
            category.scheme.strip! unless category.scheme.blank?
            @categories << category
          end
        end
      end
      return @categories
    end
  
    # Returns a list of the feed's images
    def images
      if @images.nil?
        @images = []
        image_nodes = FeedTools::XmlHelper.combine_xpaths_all(
          self.channel_node, [
            "image",
            "logo",
            "apple-wallpapers:image",
            "imageUrl"
          ]
        )
        unless image_nodes.blank?
          for image_node in image_nodes
            image = FeedTools::Image.new
            image.href = FeedTools::XmlHelper.try_xpaths(image_node, [
              "url/text()",
              "@rdf:resource",
              "@href",
              "text()"
            ], :select_result_value => true)
            if image.href.nil? && image_node.base_uri != nil
              image.href = ""
            end
            begin
              if !(image.href =~ /^file:/) &&
                  !FeedTools::UriHelper.is_uri?(image.href)
                image.href = FeedTools::UriHelper.resolve_relative_uri(
                  image.href, [image_node.base_uri, self.base_uri])
              end
            rescue
            end
            if self.configurations[:url_normalization_enabled]
              image.href = FeedTools::UriHelper.normalize_url(image.href)
            end            
            image.href.strip! unless image.href.nil?
            next if image.href.blank?
            image.title = FeedTools::XmlHelper.try_xpaths(image_node,
              ["title/text()"], :select_result_value => true)
            image.title.strip! unless image.title.nil?
            image.description = FeedTools::XmlHelper.try_xpaths(image_node,
              ["description/text()"], :select_result_value => true)
            image.description.strip! unless image.description.nil?
            image.link = FeedTools::XmlHelper.try_xpaths(image_node,
              ["link/text()"], :select_result_value => true)
            image.link.strip! unless image.link.nil?
            image.height = FeedTools::XmlHelper.try_xpaths(image_node,
              ["height/text()"], :select_result_value => true).to_i
            image.height = nil if image.height <= 0
            image.width = FeedTools::XmlHelper.try_xpaths(image_node,
              ["width/text()"], :select_result_value => true).to_i
            image.width = nil if image.width <= 0
            image.style = FeedTools::XmlHelper.try_xpaths(image_node, [
              "style/text()",
              "@style"
            ], :select_result_value => true)
            image.style.strip! unless image.style.nil?
            image.style.downcase! unless image.style.nil?
            @images << image unless image.href.nil?
          end
        end
        for link_object in self.links
          if link_object.type != nil && link_object.type =~ /^image/
            image = FeedTools::Image.new
            image.href = link_object.href
            image.title = link_object.title
            @images << image unless image.href.nil?
          end
        end
      end
      return @images
    end

    # Returns the feed's copyright information
    def rights
      if @rights.nil?
        repair_entities = false
        rights_node = FeedTools::XmlHelper.try_xpaths(self.channel_node, [
          "atom10:copyright",
          "atom03:copyright",
          "atom:copyright",
          "copyright",
          "copyrights",
          "dc:rights",
          "rights"
        ])
        @rights = FeedTools::HtmlHelper.process_text_construct(rights_node,
          self.feed_type, self.feed_version)
        if self.feed_type == "atom" ||
            self.configurations[:always_strip_wrapper_elements]
          @rights = FeedTools::HtmlHelper.strip_wrapper_element(@rights)
        end
      end
      return @rights
    end

    # Sets the feed's rights information
    def rights=(new_rights)
      @rights = new_rights
    end

    def license #:nodoc:
      raise "Not implemented yet."
    end
    
    def license=(new_license) #:nodoc:
      raise "Not implemented yet."
    end
    
    # Returns the number of seconds before the feed should expire
    def time_to_live
      if @time_to_live.nil?
        unless channel_node.nil?
          # get the feed time to live from the xml document
          update_frequency = FeedTools::XmlHelper.try_xpaths(
            self.channel_node,
            ["syn:updateFrequency/text()"], :select_result_value => true)
          if !update_frequency.blank?
            update_period = FeedTools::XmlHelper.try_xpaths(
              self.channel_node,
              ["syn:updatePeriod/text()"], :select_result_value => true)
            if update_period == "daily"
              @time_to_live = update_frequency.to_i.day
            elsif update_period == "weekly"
              @time_to_live = update_frequency.to_i.week
            elsif update_period == "monthly"
              @time_to_live = update_frequency.to_i.month
            elsif update_period == "yearly"
              @time_to_live = update_frequency.to_i.year
            else
              # hourly
              @time_to_live = update_frequency.to_i.hour
            end
          end
          if @time_to_live.nil?
            # usually expressed in minutes
            update_frequency = FeedTools::XmlHelper.try_xpaths(
              self.channel_node, ["ttl/text()"],
              :select_result_value => true)
            if !update_frequency.blank?
              update_span = FeedTools::XmlHelper.try_xpaths(
                self.channel_node, ["ttl/@span"],
                :select_result_value => true)
              if update_span == "seconds"
                @time_to_live = update_frequency.to_i
              elsif update_span == "minutes"
                @time_to_live = update_frequency.to_i.minute
              elsif update_span == "hours"
                @time_to_live = update_frequency.to_i.hour
              elsif update_span == "days"
                @time_to_live = update_frequency.to_i.day
              elsif update_span == "weeks"
                @time_to_live = update_frequency.to_i.week
              elsif update_span == "months"
                @time_to_live = update_frequency.to_i.month
              elsif update_span == "years"
                @time_to_live = update_frequency.to_i.year
              else
                @time_to_live = update_frequency.to_i.minute
              end
            end
          end
          if @time_to_live.nil?
            @time_to_live = 0
            update_frequency_days =
              FeedTools::XmlHelper.try_xpaths(self.channel_node,
              ["schedule/intervaltime/@day"], :select_result_value => true)
            update_frequency_hours =
              FeedTools::XmlHelper.try_xpaths(self.channel_node,
              ["schedule/intervaltime/@hour"], :select_result_value => true)
            update_frequency_minutes =
              FeedTools::XmlHelper.try_xpaths(self.channel_node,
              ["schedule/intervaltime/@min"], :select_result_value => true)
            update_frequency_seconds =
              FeedTools::XmlHelper.try_xpaths(self.channel_node,
              ["schedule/intervaltime/@sec"], :select_result_value => true)
            if !update_frequency_days.blank?
              @time_to_live = @time_to_live + update_frequency_days.to_i.day
            end
            if !update_frequency_hours.blank?
              @time_to_live = @time_to_live + update_frequency_hours.to_i.hour
            end
            if !update_frequency_minutes.blank?
              @time_to_live = @time_to_live +
                update_frequency_minutes.to_i.minute
            end
            if !update_frequency_seconds.blank?
              @time_to_live = @time_to_live + update_frequency_seconds.to_i
            end
            if @time_to_live == 0
              @time_to_live = self.configurations[:default_ttl].to_i
            end
          end
        end
      end
      if @time_to_live.nil? || @time_to_live == 0
        # Default to one hour
        @time_to_live = self.configurations[:default_ttl].to_i
      elsif self.configurations[:max_ttl] != nil &&
          self.configurations[:max_ttl] != 0 &&
          @time_to_live >= self.configurations[:max_ttl].to_i
        @time_to_live = self.configurations[:max_ttl].to_i
      end
      @time_to_live = @time_to_live.round
      return @time_to_live
    end

    # Sets the feed time to live
    def time_to_live=(new_time_to_live)
      @time_to_live = new_time_to_live.round
      @time_to_live = 30.minutes if @time_to_live < 30.minutes
    end

    # Returns the feed's cloud
    def cloud
      if @cloud.nil?
        @cloud = FeedTools::Cloud.new
        @cloud.domain = FeedTools::XmlHelper.try_xpaths(
          self.channel_node, ["cloud/@domain"],
          :select_result_value => true)
        @cloud.port = FeedTools::XmlHelper.try_xpaths(
          self.channel_node, ["cloud/@port"],
          :select_result_value => true)
        @cloud.path = FeedTools::XmlHelper.try_xpaths(
          self.channel_node, ["cloud/@path"],
          :select_result_value => true)
        @cloud.register_procedure =
          FeedTools::XmlHelper.try_xpaths(
            self.channel_node, ["cloud/@registerProcedure"],
            :select_result_value => true)
        @cloud.protocol =
          FeedTools::XmlHelper.try_xpaths(
            self.channel_node, ["cloud/@protocol"],
            :select_result_value => true)
        @cloud.protocol.downcase unless @cloud.protocol.nil?
        @cloud.port = @cloud.port.to_s.to_i
        @cloud.port = nil if @cloud.port == 0
      end
      return @cloud
    end
  
    # Sets the feed's cloud
    def cloud=(new_cloud)
      @cloud = new_cloud
    end
  
    # Returns the feed's text input field
    def text_input
      if @text_input.nil?
        @text_input = FeedTools::TextInput.new
        text_input_node =
          FeedTools::XmlHelper.try_xpaths(self.channel_node, ["textInput"])
        unless text_input_node.nil?
          @text_input.title =
            FeedTools::XmlHelper.try_xpaths(text_input_node,
              ["title/text()"],
              :select_result_value => true)
          @text_input.description =
            FeedTools::XmlHelper.try_xpaths(text_input_node,
              ["description/text()"],
              :select_result_value => true)
          @text_input.link =
            FeedTools::XmlHelper.try_xpaths(text_input_node,
              ["link/text()"],
              :select_result_value => true)
          @text_input.name =
            FeedTools::XmlHelper.try_xpaths(text_input_node,
              ["name/text()"],
              :select_result_value => true)
        end
      end
      return @text_input
    end
    
    # Returns the feed generator
    def generator
      if @generator.nil?
        @generator = FeedTools::XmlHelper.try_xpaths(
          self.channel_node, ["generator/text()"],
          :select_result_value => true)
        unless @generator.nil?
          @generator =
            FeedTools::HtmlHelper.convert_html_to_plain_text(@generator)
        end
      end
      return @generator
    end

    # Sets the feed generator
    #
    # Note: Setting this variable will NOT cause this to appear in any
    # generated output.  The generator string is created from the
    # <tt>:generator_name</tt> and <tt>:generator_href</tt> configuration
    # variables.
    def generator=(new_generator)
      @generator = new_generator
    end

    # Returns the feed docs
    def docs
      if @docs.nil?
        @docs = FeedTools::XmlHelper.try_xpaths(
          self.channel_node, ["docs/text()"],
          :select_result_value => true)
        begin
          if !(@docs =~ /^file:/) &&
              !FeedTools::UriHelper.is_uri?(@docs)
            channel_base_uri = nil
            unless self.channel_node.nil?
              channel_base_uri = self.channel_node.base_uri
            end
            @docs = FeedTools::UriHelper.resolve_relative_uri(
              @docs, [channel_base_uri, self.base_uri])
          end
        rescue
        end
        if self.configurations[:url_normalization_enabled]
          @docs = FeedTools::UriHelper.normalize_url(@docs)
        end
      end
      return @docs
    end

    # Sets the feed docs
    def docs=(new_docs)
      @docs = new_docs
    end

    # Returns the feed language
    def language
      if @language.nil?
        @language = FeedTools::XmlHelper.select_not_blank([
          FeedTools::XmlHelper.try_xpaths(self.channel_node, [
            "language/text()",
            "dc:language/text()",
            "@dc:language",
            "@xml:lang",
            "xml:lang/text()"
          ], :select_result_value => true),
          FeedTools::XmlHelper.try_xpaths(self.root_node, [
            "@xml:lang",
            "xml:lang/text()"
          ], :select_result_value => true)
        ])
        if @language.blank?
          @language = "en-us"
        end
        @language.gsub!(/_/, "-")
        @language = @language.downcase
        if @language.split('-').size > 1
          @language =
            "#{@language.split('-').first}-" +
            "#{@language.split('-').last.upcase}"
        end
      end
      return @language
    end

    # Sets the feed language
    def language=(new_language)
      @language = new_language
    end
  
    # Returns true if this feed contains explicit material.
    def explicit?
      if @explicit.nil?
        explicit_string = FeedTools::XmlHelper.try_xpaths(self.channel_node, [
          "media:adult/text()",
          "itunes:explicit/text()"
        ], :select_result_value => true)
        if explicit_string == "true" || explicit_string == "yes"
          @explicit = true
        else
          @explicit = false
        end
      end
      return @explicit
    end

    # Sets whether or not the feed contains explicit material
    def explicit=(new_explicit)
      @explicit = (new_explicit ? true : false)
    end
  
    # Returns the feed entries
    def entries
      if @entries.nil?
        raw_entries = FeedTools::XmlHelper.select_not_blank([
          FeedTools::XmlHelper.try_xpaths_all(self.channel_node, [
            "atom10:entry",
            "atom03:entry",
            "atom:entry",
            "entry"
          ]),
          FeedTools::XmlHelper.try_xpaths_all(self.root_node, [
            "rss10:item",
            "rss11:items/rss11:item",
            "rss11:items/item",
            "items/rss11:item",
            "items/item",
            "item",
            "atom10:entry",
            "atom03:entry",
            "atom:entry",
            "entry",
            "story"
          ]),
          FeedTools::XmlHelper.try_xpaths_all(self.channel_node, [
            "rss10:item",
            "rss11:items/rss11:item",
            "rss11:items/item",
            "items/rss11:item",
            "items/item",
            "item",
            "story"
          ])
        ])

        # create the individual feed items
        @entries = []
        unless raw_entries.blank?
          for entry_node in raw_entries.reverse
            new_entry = FeedItem.new
            new_entry.feed_data = entry_node.to_s
            new_entry.feed_data_type = self.feed_data_type
            new_entry.root_node = entry_node
            if new_entry.root_node.namespace.blank?
              new_entry.root_node.add_namespace(self.root_node.namespace)
            end
            @entries << new_entry
          end
        end
      end
    
      # Sort the items
      if self.configurations[:entry_sorting_property] == "time"
        @entries = @entries.sort do |a, b|
          (b.time or Time.utc(1970)) <=> (a.time or Time.utc(1970))
        end
      elsif self.configurations[:entry_sorting_property] != nil
        sorting_property = self.configurations[:entry_sorting_property]
        @entries = @entries.sort do |a, b|
          eval("a.#{sorting_property}") <=> eval("b.#{sorting_property}")
        end
      else
        return @entries.reverse
      end
      return @entries
    end

    # Sets the entries array to a new array.
    def entries=(new_entries)
      for entry in new_entries
        unless entry.kind_of? FeedTools::FeedItem
          raise ArgumentError,
            "You should only add FeedItem objects to the entries array."
        end
      end
      @entries = new_entries
    end
    
    # Syntactic sugar for appending feed items to a feed.
    def <<(new_entry)
      @entries ||= []
      unless new_entry.kind_of? FeedTools::FeedItem
        raise ArgumentError,
          "You should only add FeedItem objects to the entries array."
      end
      @entries << new_entry
    end
  
    # The time that the feed was last requested from the remote server.  Nil
    # if it has never been pulled, or if it was created from scratch.
    def last_retrieved
      unless self.cache_object.nil?
        @last_retrieved = self.cache_object.last_retrieved
      end
      return @last_retrieved
    end
  
    # Sets the time that the feed was last updated.
    def last_retrieved=(new_last_retrieved)
      @last_retrieved = new_last_retrieved
      unless self.cache_object.nil?
        self.cache_object.last_retrieved = new_last_retrieved
      end
    end
  
    # True if this feed contains audio content enclosures
    def podcast?
      podcast = false
      self.items.each do |item|
        item.enclosures.each do |enclosure|
          podcast = true if enclosure.audio?
        end
      end
      return podcast
    end

    # True if this feed contains video content enclosures
    def vidlog?
      vidlog = false
      self.items.each do |item|
        item.enclosures.each do |enclosure|
          vidlog = true if enclosure.video?
        end
      end
      return vidlog
    end
  
    # True if the feed was not last retrieved from the cache.
    def live?
      return @live
    end
  
    # True if the feed has expired and must be reacquired from the remote
    # server.
    def expired?
      if (self.last_retrieved == nil)
        return true
      elsif (self.time_to_live < 30.minutes)
        return (self.last_retrieved + 30.minutes) < Time.now.gmtime
      else
        return (self.last_retrieved + self.time_to_live) < Time.now.gmtime
      end
    end
  
    # Forces this feed to expire.
    def expire!
      self.last_retrieved = Time.mktime(1970).gmtime
      self.save
    end

    # A hook method that is called during the feed generation process.
    # Overriding this method will enable additional content to be
    # inserted into the feed.
    def build_xml_hook(feed_type, version, xml_builder)
      return nil
    end

    # Generates xml based on the content of the feed
    def build_xml(feed_type=(self.feed_type or "atom"), feed_version=nil,
        xml_builder=Builder::XmlMarkup.new(
          :indent => 2, :escape_attrs => false))
      
      if self.find_node("access:restriction/@relationship").to_s == "deny"
        raise StandardError,
          "Operation not permitted.  This feed denies redistribution."
      elsif self.find_node("@indexing:index").to_s == "no"
        raise StandardError,
          "Operation not permitted.  This feed denies redistribution."
      end
      
      self.full_parse()
      
      xml_builder.instruct! :xml, :version => "1.0",
        :encoding => (self.configurations[:output_encoding] or "utf-8")
      if feed_type.nil?
        feed_type = self.feed_type
      end
      if feed_version.nil?
        feed_version = self.feed_version
      end
      if feed_type == "rss" &&
          (feed_version == nil || feed_version <= 0.0)
        feed_version = 1.0
      elsif feed_type == "atom" &&
          (feed_version == nil || feed_version <= 0.0)
        feed_version = 1.0
      end
      if feed_type == "rss" &&
          (feed_version == 0.9 || feed_version == 1.0 || feed_version == 1.1)
        # RDF-based rss format
        return xml_builder.tag!("rdf:RDF",
            "xmlns" => FEED_TOOLS_NAMESPACES['rss10'],
            "xmlns:content" => FEED_TOOLS_NAMESPACES['content'],
            "xmlns:rdf" => FEED_TOOLS_NAMESPACES['rdf'],
            "xmlns:dc" => FEED_TOOLS_NAMESPACES['dc'],
            "xmlns:syn" => FEED_TOOLS_NAMESPACES['syn'],
            "xmlns:admin" => FEED_TOOLS_NAMESPACES['admin'],
            "xmlns:taxo" => FEED_TOOLS_NAMESPACES['taxo'],
            "xmlns:itunes" => FEED_TOOLS_NAMESPACES['itunes'],
            "xmlns:media" => FEED_TOOLS_NAMESPACES['media']) do
          channel_attributes = {}
          unless self.link.nil?
            channel_attributes["rdf:about"] =
              FeedTools::HtmlHelper.escape_entities(self.link)
          end
          xml_builder.channel(channel_attributes) do
            unless self.title.blank?
              xml_builder.title(
                FeedTools::HtmlHelper.strip_html_tags(self.title))
            else
              xml_builder.title
            end
            unless self.link.blank?
              xml_builder.link(self.link)
            else
              xml_builder.link
            end
            unless images.blank?
              xml_builder.image("rdf:resource" =>
                FeedTools::HtmlHelper.escape_entities(
                  images.first.url))
            end
            unless description.nil? || description == ""
              xml_builder.description(description)
            else
              xml_builder.description
            end
            unless self.language.blank?
              xml_builder.tag!("dc:language", self.language)
            end
            unless self.rights.blank?
              xml_builder.tag!("dc:rights", self.rights)
            end
            xml_builder.tag!("syn:updatePeriod", "hourly")
            xml_builder.tag!("syn:updateFrequency",
              (self.time_to_live / 1.hour).to_s)
            xml_builder.tag!("syn:updateBase", Time.mktime(1970).iso8601)
            xml_builder.items do
              xml_builder.tag!("rdf:Seq") do
                unless items.nil?
                  for item in items
                    if item.link.nil?
                      raise "Cannot generate an rdf-based feed with a nil " +
                        "item link field."
                    end
                    xml_builder.tag!("rdf:li", "rdf:resource" =>
                      FeedTools::HtmlHelper.escape_entities(item.link))
                  end
                end
              end
            end
            xml_builder.tag!(
              "admin:generatorAgent",
              "rdf:resource" => self.configurations[:generator_href])
            build_xml_hook(feed_type, feed_version, xml_builder)
          end
          unless self.images.blank?
            best_image = nil
            for image in self.images
              if image.link != nil
                best_image = image
                break
              end
            end
            best_image = self.images.first if best_image.nil?
            xml_builder.image("rdf:about" =>
                FeedTools::HtmlHelper.escape_entities(best_image.url)) do
              if !best_image.title.blank?
                xml_builder.title(best_image.title)
              elsif !self.title.blank?
                xml_builder.title(self.title)
              else
                xml_builder.title
              end
              unless best_image.url.blank?
                xml_builder.url(best_image.url)
              end
              if !best_image.link.blank?
                xml_builder.link(best_image.link)
              elsif !self.link.blank?
                xml_builder.link(self.link)
              else
                xml_builder.link
              end
            end
          end
          unless items.nil?
            for item in items
              item.build_xml(feed_type, feed_version, xml_builder)
            end
          end
        end
      elsif feed_type == "rss"
        # normal rss format
        return xml_builder.rss("version" => "2.0",
            "xmlns:content" => FEED_TOOLS_NAMESPACES['content'],
            "xmlns:rdf" => FEED_TOOLS_NAMESPACES['rdf'],
            "xmlns:dc" => FEED_TOOLS_NAMESPACES['dc'],
            "xmlns:taxo" => FEED_TOOLS_NAMESPACES['taxo'],
            "xmlns:trackback" => FEED_TOOLS_NAMESPACES['trackback'],
            "xmlns:itunes" => FEED_TOOLS_NAMESPACES['itunes'],
            "xmlns:media" => FEED_TOOLS_NAMESPACES['media']) do
          xml_builder.channel do
            unless self.title.blank?
              xml_builder.title(
                FeedTools::HtmlHelper.strip_html_tags(self.title))
            end
            unless self.link.blank?
              xml_builder.link(link)
            end
            unless self.description.blank?
              xml_builder.description(description)
            else
              xml_builder.description
            end
            unless self.author.email.blank?
              xml_builder.managingEditor(self.author.email)
            end
            unless self.publisher.email.blank?
              xml_builder.webMaster(self.publisher.email)
            end
            unless self.published.blank?
              xml_builder.pubDate(self.published.rfc822)
            end
            unless self.updated.blank?
              xml_builder.lastBuildDate(self.updated.rfc822)
            end
            unless self.copyright.blank?
              xml_builder.copyright(self.copyright)
            end
            unless self.language.blank?
              xml_builder.language(self.language)
            end
            xml_builder.ttl((time_to_live / 1.minute).to_s)
            xml_builder.generator(
              self.configurations[:generator_href])
            build_xml_hook(feed_type, feed_version, xml_builder)
            unless items.nil?
              for item in items
                item.build_xml(feed_type, feed_version, xml_builder)
              end
            end
          end
        end
      elsif feed_type == "atom" && feed_version == 0.3
        raise "Atom 0.3 is obsolete."
      elsif feed_type == "atom" && feed_version == 1.0
        # normal atom format
        return xml_builder.feed("xmlns" => FEED_TOOLS_NAMESPACES['atom10'],
            "xml:lang" => language) do
          unless title.blank?
            xml_builder.title(title,
                "type" => "html")
          end
          xml_builder.author do
            unless self.author.nil? || self.author.name.nil?
              xml_builder.name(self.author.name)
            else
              xml_builder.name("n/a")
            end
            unless self.author.nil? || self.author.email.nil?
              xml_builder.email(self.author.email)
            end
            unless self.author.nil? || self.author.url.nil?
              xml_builder.uri(self.author.url)
            end
          end
          unless self.href.blank?
            xml_builder.link("href" => self.href,
                "rel" => "self",
                "type" => "application/atom+xml")
          end
          unless self.link.blank?
            xml_builder.link(
              "href" =>
                FeedTools::HtmlHelper.escape_entities(self.link),
              "rel" => "alternate")
          end
          unless self.subtitle.blank?
            xml_builder.subtitle(self.subtitle,
                "type" => "html")
          end
          if self.updated != nil
            xml_builder.updated(self.updated.iso8601)
          elsif self.time != nil
            # Not technically correct, but a heck of a lot better
            # than the Time.now fall-back.
            xml_builder.updated(self.time.iso8601)
          else
            xml_builder.updated(Time.now.gmtime.iso8601)
          end
          unless self.rights.blank?
            xml_builder.rights(self.rights)
          end
          xml_builder.generator(self.configurations[:generator_name] +
            " - " + self.configurations[:generator_href])
          if self.id != nil
            unless FeedTools::UriHelper.is_uri? self.id
              if self.link != nil
                xml_builder.id(FeedTools::UriHelper.build_urn_uri(self.link))
              else
                raise "The unique id must be a valid URI."
              end
            else
              xml_builder.id(self.id)
            end
          elsif self.link != nil
            xml_builder.id(FeedTools::UriHelper.build_urn_uri(self.link))
          elsif self.url != nil
            xml_builder.id(FeedTools::UriHelper.build_urn_uri(self.url))
          else
            raise "Cannot build feed, missing feed unique id."
          end
          build_xml_hook(feed_type, feed_version, xml_builder)
          unless items.nil?
            for item in items
              item.build_xml(feed_type, feed_version, xml_builder)
            end
          end
        end
      else
        raise "Unsupported feed format/version."
      end
    end

    # Persists the current feed state to the cache.
    def save
      if self.configurations[:feed_cache].nil?
        # The cache is disabled for this feed, do nothing.
        return
      end
      if self.feed_data.blank? && self.http_headers.blank?
        # There's no data, nothing to save.
        return
      end
      if self.http_headers['content-type'] =~ /text\/html/ ||
          self.http_headers['content-type'] =~ /application\/xhtml\+xml/
        if self.title.nil? && self.link.nil? && self.entries.blank?
          # Don't save html pages to the cache, it messes with
          # autodiscovery.
          return
        end
      end
      unless self.href =~ /^file:\/\//
        if FeedTools.feed_cache.nil?
          raise "Caching is currently disabled.  Cannot save to cache."
        elsif self.href.nil?
          raise "The url field must be set to save to the cache."
        elsif self.cache_object.nil?
          raise "The cache_object is currently nil.  Cannot save to cache."
        else
          self.cache_object.href = self.href
          unless self.feed_data.nil?
            self.cache_object.title = self.title
            self.cache_object.link = self.link
            self.cache_object.feed_data = self.feed_data
            self.cache_object.feed_data_type = self.feed_data_type.to_s
          end
          self.cache_object.http_headers = self.http_headers.to_yaml
          self.cache_object.last_retrieved = self.last_retrieved
          Thread.pass
          self.cache_object.save
        end
      end
    end

    alias_method :url, :href
    alias_method :url=, :href=  
    alias_method :tagline, :subtitle
    alias_method :tagline=, :subtitle=
    alias_method :description, :subtitle
    alias_method :description=, :subtitle=
    alias_method :abstract, :subtitle
    alias_method :abstract=, :subtitle=
    alias_method :copyright, :rights
    alias_method :copyright=, :rights=
    alias_method :ttl, :time_to_live
    alias_method :ttl=, :time_to_live=
    alias_method :guid, :id
    alias_method :guid=, :id=
    alias_method :items, :entries
    alias_method :items=, :entries=
  
    # passes missing methods to the cache_object
    def method_missing(msg, *params)
      if self.cache_object.nil?
        raise NoMethodError, "Invalid method #{msg.to_s}"
      end
      return self.cache_object.send(msg, params)
    end

    # passes missing methods to the FeedTools.feed_cache
    def Feed.method_missing(msg, *params)
      if FeedTools.feed_cache.nil?
        raise NoMethodError, "Invalid method Feed.#{msg.to_s}"
      end
      result = FeedTools.feed_cache.send(msg, params)
      if result.kind_of? FeedTools.feed_cache
        result = Feed.open(result.url)
      end
      return result
    end
  
    # Returns a simple representation of the feed object's state.
    def inspect
      return "#<FeedTools::Feed:0x#{self.object_id.to_s(16)} URL:#{self.href}>"
    end
    
    # Allows sorting feeds by title
    def <=>(other_feed)
      return self.title.to_s <=> other_feed.title.to_s
    end
  end
end