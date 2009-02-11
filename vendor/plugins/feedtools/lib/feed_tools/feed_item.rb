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

require 'feed_tools/feed_structures'

module FeedTools
  # The <tt>FeedTools::FeedItem</tt> class represents the structure of
  # a single item within a web feed.
  class FeedItem
    # Initialize the feed object
    def initialize
      super
      @feed_data = nil
      @feed_data_type = :xml
      @xml_document = nil
      @root_node = nil
      @title = nil
      @id = nil
      @time = Time.now.gmtime
      @version = FeedTools::FEED_TOOLS_VERSION::STRING
    end
    
    # Breaks any references that the feed entry may be keeping around, thus
    # making the job of the garbage collector much, much easier.  Call this
    # method prior to feed entries going out of scope to prevent memory leaks.
    def dispose()
      @feed_data = nil
      @feed_data_type = nil
      @xml_document = nil
      @root_node = nil
      @title = nil
      @id = nil
      @time = nil
    end

    # Returns the parent feed of this feed item
    # Warning, this method may be slow if you have a
    # large number of FeedTools::Feed objects.  Can't
    # use a direct reference to the parent because it plays
    # havoc with the garbage collector.  Could've used
    # a WeakRef object, but really, if there are multiple
    # parent feeds, something is going to go wrong, and the
    # programmer needs to be notified.  A WeakRef
    # implementation can't detect this condition.
    def feed
      parent_feed = nil
      ObjectSpace.each_object(FeedTools::Feed) do |feed|
        if feed.instance_variable_get("@entries").nil?
          feed.items
        end
        unsorted_items = feed.instance_variable_get("@entries")
        for item in unsorted_items
          if item.object_id == self.object_id
            if parent_feed.nil?
              parent_feed = feed
              break
            else
              raise "Multiple parent feeds found."
            end
          end
        end
      end
      return parent_feed
    end
    
    # Does a full parse of the feed item.
    def full_parse
      self.configurations
      
      self.encoding
      self.xml_document
      self.root_node
      
      self.feed_type
      self.feed_version
      
      self.id
      self.title
      self.content
      self.summary
      self.links
      self.link
      self.comments
      self.time
      self.updated
      self.published
      self.source
      self.categories
      self.tags
      self.images
      self.rights
      self.author
      self.publisher

      self.itunes_summary
      self.itunes_subtitle
      self.itunes_image_link
      self.itunes_author
      self.itunes_duration

      self.media_text
      self.media_thumbnail_link

      self.explicit?
    end
    
    # Returns a duplicate object suitable for serialization
    def serializable
      self.full_parse()
      feed_item_to_dump = self.dup
      feed_item_to_dump.author
      feed_item_to_dump.publisher
      feed_item_to_dump.instance_variable_set("@xml_document", nil)
      feed_item_to_dump.instance_variable_set("@root_node", nil)
      return feed_item_to_dump
    end
    
    # Returns the load options for this feed.
    def configurations
      if @configurations.blank?
        parent_feed = self.feed
        if parent_feed != nil
          @configurations = parent_feed.configurations.dup
        else
          @configurations = FeedTools.configurations.dup
        end
      end
      return @configurations
    end
    
    # Sets the load options for this feed.
    def configurations=(new_configurations)
      @configurations = new_configurations
    end
    
    # Returns the feed item's encoding.
    def encoding
      if @encoding.nil?
        parent_feed = self.feed
        if parent_feed != nil
          @encoding = parent_feed.encoding
        else
          @encoding = nil
        end
      end
      return @encoding
    end
    
    # Returns the feed item's raw data.
    def feed_data
      return @feed_data
    end

    # Sets the feed item's data.
    def feed_data=(new_feed_data)
      @time = nil
      @feed_data = new_feed_data
    end

    # Returns the feed item's data type.
    def feed_data_type
      return @feed_data_type
    end

    # Sets the feed item's data type.
    def feed_data_type=(new_feed_data_type)
      @feed_data_type = new_feed_data_type
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
          # TODO: :ignore_whitespace_nodes => :all
          # Add that?
          # ======================================
          @xml_document = REXML::Document.new(self.feed_data)
        end
      end
      return @xml_document
    end

    # Returns the first node within the root_node that matches the xpath query.
    def find_node(xpath, select_result_value=false)
      if self.feed_data_type != :xml
        raise "The feed data type is not xml."
      end
      return FeedTools::XmlHelper.try_xpaths(self.root_node, [xpath],
        :select_result_value => select_result_value)
    end

    # Returns all nodes within the root_node that match the xpath query.
    def find_all_nodes(xpath, select_result_value=false)
      if self.feed_data_type != :xml
        raise "The feed data type is not xml."
      end
      return FeedTools::XmlHelper.try_xpaths_all(self.root_node, [xpath],
        :select_result_value => select_result_value)
    end

    # Returns the root node of the feed item.
    def root_node
      if @root_node.nil?
        if self.xml_document.nil?
          return nil
        end
        @root_node = self.xml_document.root
      end
      return @root_node
    end
    
    # Sets the root node of the feed item.
    # 
    # This allows namespace information to be inherited by the feed item
    # from the feed itself.  When creating individual nodes from scratch,
    # the <tt>feed_data=</tt> method should be used instead.
    def root_node=(new_root_node)
      @root_node = new_root_node
    end
    
    # Returns the feed type of this item
    def feed_type
      if @feed_type.nil?
        parent_feed = self.feed
        @feed_type = parent_feed.feed_type unless parent_feed.nil?
      end
      return @feed_type
    end
    
    # Returns the feed version of this item
    def feed_version
      if @feed_version.nil?
        parent_feed = self.feed
        @feed_version = parent_feed.feed_version unless parent_feed.nil?
      end
      return @feed_version
    end

    # Returns the feed items's unique id
    def id
      if @id.nil?
        @id = FeedTools::XmlHelper.try_xpaths(self.root_node, [
          "atom10:id/@gr:original-id",
          "atom03:id/@gr:original-id",
          "atom:id/@gr:original-id",
          "id/@gr:original-id",
          "atom10:id/text()",
          "atom03:id/text()",
          "atom:id/text()",
          "id/text()",
          "guid/text()"
        ], :select_result_value => true)
      end
      return @id
    end

    # Sets the feed item's unique id
    def id=(new_id)
      @id = new_id
    end

    # Returns the feed item title
    def title
      if @title.nil?
        repair_entities = false
        title_node = FeedTools::XmlHelper.try_xpaths(self.root_node, [
          "atom10:title",
          "atom03:title",
          "atom:title",
          "title",
          "dc:title",
          "headline"
        ])
        @title = FeedTools::HtmlHelper.process_text_construct(title_node,
          self.feed_type, self.feed_version)
        if self.feed_type == "atom" ||
            self.configurations[:always_strip_wrapper_elements]
          @title = FeedTools::HtmlHelper.strip_wrapper_element(@title)
        end
        if !@title.blank? && self.configurations[:strip_comment_count]
          # Some blogging tools include the number of comments in a post
          # in the title... this is supremely ugly, and breaks any
          # applications which expect the title to be static, so we're
          # gonna strip them out.
          #
          # If for some incredibly wierd reason you need the actual
          # unstripped title, just use find_node("title/text()").to_s
          @title = @title.strip.gsub(/\[\d*\]$/, "").strip
        end
        @title = nil if @title.blank?
      end
      return @title
    end
    
    # Sets the feed item title
    def title=(new_title)
      @title = new_title
    end

    # Returns the feed item content
    def content
      if @content.nil?
        repair_entities = false
        content_node = FeedTools::XmlHelper.try_xpaths(self.root_node, [
          "atom10:content",
          "atom03:content",
          "atom:content",
          "body/datacontent",
          "xhtml:body",
          "body",
          "xhtml:div",
          "div",
          "p:payload",
          "payload",
          "content:encoded",
          "content",
          "fullitem",
          "encoded",
          "description",
          "tagline",
          "subtitle",
          "atom10:summary",
          "atom03:summary",
          "atom:summary",
          "summary",
          "abstract",
          "blurb",
          "info"
        ])
        @content = FeedTools::HtmlHelper.process_text_construct(content_node,
          self.feed_type, self.feed_version)
        if self.feed_type == "atom" ||
            self.configurations[:always_strip_wrapper_elements]
          @content = FeedTools::HtmlHelper.strip_wrapper_element(@content)
        end
        if @content.blank?
          @content = self.media_text
        end
        if @content.blank?
          @content = self.itunes_summary
        end
        if @content.blank?
          @content = self.itunes_subtitle
        end
      end
      return @content
    end

    # Sets the feed item content
    def content=(new_content)
      @content = new_content
    end

    # Returns the feed item summary
    def summary
      if @summary.nil?
        repair_entities = false
        summary_node = FeedTools::XmlHelper.try_xpaths(self.root_node, [
          "atom10:summary",
          "atom03:summary",
          "atom:summary",
          "summary",
          "abstract",
          "blurb",
          "description",
          "tagline",
          "subtitle",
          "xhtml:body",
          "body",
          "xhtml:div",
          "div",
          "p:payload",
          "payload",
          "fullitem",
          "content:encoded",
          "encoded",
          "atom10:content",
          "atom03:content",
          "atom:content",
          "content",
          "info",
          "body/datacontent"
        ])
        @summary = FeedTools::HtmlHelper.process_text_construct(summary_node,
          self.feed_type, self.feed_version)
        if self.feed_type == "atom" ||
            self.configurations[:always_strip_wrapper_elements]
          @summary = FeedTools::HtmlHelper.strip_wrapper_element(@summary)
        end
        if @summary.blank?
          @summary = self.media_text
        end
        if @summary.blank?
          @summary = self.itunes_summary
        end
        if @summary.blank?
          @summary = self.itunes_subtitle
        end
      end
      return @summary
    end

    # Sets the feed item summary
    def summary=(new_summary)
      @summary = new_summary
    end
    
    # Returns the links collection
    def links
      if @links.nil?
        @links = []
        link_nodes =
          FeedTools::XmlHelper.combine_xpaths_all(self.root_node, [
            "atom10:link",
            "atom03:link",
            "atom:link",
            "link",
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
            "@url",
            "text()"
          ], :select_result_value => true)
          if link_object.href.nil? && link_node.base_uri != nil
            link_object.href = ""
          end
          begin
            if !(link_object.href =~ /^file:/) &&
                !FeedTools::UriHelper.is_uri?(link_object.href)
              stored_base_uri =
                FeedTools::GenericHelper.recursion_trap(:feed_link) do
                  self.feed.base_uri if self.feed != nil
                end
              link_object.href = FeedTools::UriHelper.resolve_relative_uri(
                link_object.href,
                [link_node.base_uri, stored_base_uri])
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
          unless link_object.hreflang.nil?
            link_object.hreflang = link_object.hreflang.downcase
          end
          link_object.rel = FeedTools::XmlHelper.try_xpaths(link_node, [
            "@atom10:rel",
            "@atom03:rel",
            "@atom:rel",
            "@rel"
          ], :select_result_value => true)
          unless link_object.rel.nil?
            link_object.rel = link_object.rel.downcase
          end
          link_object.type = FeedTools::XmlHelper.try_xpaths(link_node, [
            "@atom10:type",
            "@atom03:type",
            "@atom:type",
            "@type"
          ], :select_result_value => true)
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
          @links << link_object
        end
        if @links.empty? && self.enclosures.size > 0
          # If there's seriously nothing to link to, but there's enclosures
          # available, then add a link to the first one.
          enclosure_link = self.enclosures[0]
          link_object = FeedTools::Link.new
          link_object.href = enclosure_link.url
          link_object.type = enclosure_link.type
          @links << link_object
        end
      end
      return @links
    end
    
    # Sets the links collection
    def links=(new_links)
      @links = new_links
    end
    
    # Returns the feed item link
    def link
      if @link.nil?
        max_score = 0
        for link_object in self.links.reverse
          score = 0
          if FeedTools::HtmlHelper.html_type?(link_object.type)
            score = score + 2
          elsif link_object.type != nil
            score = score - 1
          end
          if FeedTools::HtmlHelper.xml_type?(link_object.type)
            score = score + 1
          end
          if link_object.type =~ /^video/ && self.links.size == 1
            score = score + 1
          elsif link_object.type =~ /^audio/ && self.links.size == 1
            score = score + 1
          end
          if link_object.rel == "alternate"
            score = score + 1
          end
          if link_object.rel == "self"
            score = score - 1
          end
          if score >= max_score
            max_score = score
            @link = link_object.href
          end
        end
        if @link.blank?
          @link = FeedTools::XmlHelper.try_xpaths(self.root_node, [
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
        @link = self.comments if @link.blank?
        @link = nil if @link.blank?
        begin
          if !(@link =~ /^file:/) &&
              !FeedTools::UriHelper.is_uri?(@link)
            stored_base_uri =
              FeedTools::GenericHelper.recursion_trap(:feed_link) do
                self.feed.base_uri if self.feed != nil
              end
            root_base_uri = nil
            unless self.root_node.nil?
              root_base_uri = self.root_node.base_uri
            end
            @link = FeedTools::UriHelper.resolve_relative_uri(
              @link, [root_base_uri,stored_base_uri])
          end
        rescue
        end
        if self.configurations[:url_normalization_enabled]
          @link = FeedTools::UriHelper.normalize_url(@link)
        end
      end
      return @link
    end
    
    # Sets the feed item link
    def link=(new_link)
      @link = new_link
    end
    
    # Returns the url for posting comments
    def comments
      if @comments.nil?
        @comments = FeedTools::XmlHelper.try_xpaths(self.root_node, ["comments/text()"],
          :select_result_value => true)
        begin
          if !(@comments =~ /^file:/) &&
              !FeedTools::UriHelper.is_uri?(@comments)
            root_base_uri = nil
            unless self.root_node.nil?
              root_base_uri = self.root_node.base_uri
            end
            @comments = FeedTools::UriHelper.resolve_relative_uri(
              @comments, [root_base_uri, self.base_uri])
          end
        rescue
        end
        if self.configurations[:url_normalization_enabled]
          @comments = FeedTools::UriHelper.normalize_url(@comments)
        end
      end
      return @comments
    end
    
    # Sets the url for posting comments
    def comments=(new_comments)
      @comments = new_comments
    end

    # Returns the contents of the itunes:summary element
    def itunes_summary
      if @itunes_summary.nil?
        @itunes_summary = FeedTools::XmlHelper.try_xpaths(self.root_node, [
          "itunes:summary/text()"
        ], :select_result_value => true)
        unless @itunes_summary.blank?
          @itunes_summary = FeedTools::HtmlHelper.unescape_entities(@itunes_summary)
          @itunes_summary = FeedTools::HtmlHelper.sanitize_html(@itunes_summary)
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
        @itunes_subtitle = FeedTools::XmlHelper.try_xpaths(self.root_node, [
          "itunes:subtitle/text()"
        ], :select_result_value => true)
        unless @itunes_subtitle.blank?
          @itunes_subtitle = FeedTools::HtmlHelper.unescape_entities(@itunes_subtitle)
          @itunes_subtitle = FeedTools::HtmlHelper.sanitize_html(@itunes_subtitle)
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
        @media_text = FeedTools::XmlHelper.try_xpaths(self.root_node, [
          "media:text/text()"
        ], :select_result_value => true)
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

    # Returns a list of the feed item's categories
    def categories
      if @categories.nil?
        @categories = []
        category_nodes = FeedTools::XmlHelper.try_xpaths_all(self.root_node, [
          "category",
          "dc:subject"
        ])
        for category_node in category_nodes
          category = FeedTools::Category.new
          category.term = FeedTools::XmlHelper.try_xpaths(category_node, ["@term", "text()"],
            :select_result_value => true)
          category.term.strip! unless category.term.nil?
          category.label = FeedTools::XmlHelper.try_xpaths(category_node, ["@label"],
            :select_result_value => true)
          category.label.strip! unless category.label.nil?
          category.scheme = FeedTools::XmlHelper.try_xpaths(category_node, [
            "@scheme",
            "@domain"
          ], :select_result_value => true)
          category.scheme.strip! unless category.scheme.nil?
          @categories << category
        end
      end
      return @categories
    end
    
    # Returns a list of the feed items's images
    def images
      if @images.nil?
        @images = []
        image_nodes = FeedTools::XmlHelper.try_xpaths_all(self.root_node, [
          "image",
          "logo",
          "apple-wallpapers:image",
          "imageUrl"
        ])
        unless image_nodes.blank?
          for image_node in image_nodes
            image = FeedTools::Image.new
            image.href = FeedTools::XmlHelper.try_xpaths(image_node, [
              "url/text()",
              "@rdf:resource",
              "@href",
              "@url",
              "text()"
            ], :select_result_value => true)
            if image.href.nil? && image_node.base_uri != nil
              image.href = ""
            end
            begin
              if !(image.href =~ /^file:/) &&
                  !FeedTools::UriHelper.is_uri?(image.href)
                stored_base_uri =
                  FeedTools::GenericHelper.recursion_trap(:feed_link) do
                    self.feed.base_uri if self.feed != nil
                  end
                image.href = FeedTools::UriHelper.resolve_relative_uri(
                  image.href, [image_node.base_uri, stored_base_uri])
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
            @images << image unless image.url.nil?
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
    
    # Returns the feed item itunes image link
    def itunes_image_link
      if @itunes_image_link.nil?
        @itunes_image_link = FeedTools::XmlHelper.try_xpaths(self.root_node, [
          "itunes:image/@href",
          "itunes:link[@rel='image']/@href"
        ], :select_result_value => true)
        if self.configurations[:url_normalization_enabled]
          @itunes_image_link = FeedTools::UriHelper.normalize_url(@itunes_image_link)
        end
      end
      return @itunes_image_link
    end

    # Sets the feed item itunes image link
    def itunes_image_link=(new_itunes_image_link)
      @itunes_image_link = new_itunes_image_link
    end
    
    # Returns the feed item media thumbnail link
    def media_thumbnail_link
      if @media_thumbnail_link.nil?
        @media_thumbnail_link = FeedTools::XmlHelper.try_xpaths(self.root_node, [
          "media:thumbnail/@url"
        ], :select_result_value => true)
        if self.configurations[:url_normalization_enabled]
          @media_thumbnail_link = FeedTools::UriHelper.normalize_url(@media_thumbnail_link)
        end
      end
      return @media_thumbnail_link
    end

    # Sets the feed item media thumbnail url
    def media_thumbnail_link=(new_media_thumbnail_link)
      @media_thumbnail_link = new_media_thumbnail_link
    end

    # Returns the feed item's rights information
    def rights
      if @rights.nil?
        repair_entities = false
        rights_node = FeedTools::XmlHelper.try_xpaths(self.root_node, [
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

    # Sets the feed item's rights information
    def rights=(new_rights)
      @rights = new_rights
    end

    def license #:nodoc:
      raise "Not implemented yet."
    end
    
    def license=(new_license) #:nodoc:
      raise "Not implemented yet."
    end

    # Returns all feed item enclosures
    def enclosures
      if @enclosures.nil?
        @enclosures = []
        
        # First, load up all the different possible sources of enclosures
        rss_enclosures =
          FeedTools::XmlHelper.try_xpaths_all(self.root_node, ["enclosure"])
        atom_enclosures =
          FeedTools::XmlHelper.try_xpaths_all(self.root_node, [
            "atom10:link[@rel='enclosure']",
            "atom03:link[@rel='enclosure']",
            "atom:link[@rel='enclosure']",
            "link[@rel='enclosure']"
          ])
        media_content_enclosures =
          FeedTools::XmlHelper.try_xpaths_all(self.root_node,
            ["media:content"])
        media_group_enclosures =
          FeedTools::XmlHelper.try_xpaths_all(self.root_node, ["media:group"])
          
        bogus_enclosures =
          FeedTools::XmlHelper.try_xpaths_all(self.root_node, ["video"])
          
        # TODO: Implement this
        bittorrent_enclosures =
          FeedTools::XmlHelper.try_xpaths_all(self.root_node,
            ["bitTorrent:torrent"])
        

        # Parse RSS-type enclosures.  Thanks to a few buggy enclosures
        # implementations, sometimes these also manage to show up in atom
        # files.
        for enclosure_node in rss_enclosures
          enclosure = FeedTools::Enclosure.new
          enclosure.url = FeedTools::HtmlHelper.unescape_entities(
            enclosure_node.attributes["url"].to_s)
          enclosure.type = enclosure_node.attributes["type"].to_s
          enclosure.file_size = enclosure_node.attributes["length"].to_i
          enclosure.credits = []
          enclosure.explicit = false
          @enclosures << enclosure
        end
        
        # Parse atom-type enclosures.  If there are repeats of the same
        # enclosure object, we merge the two together.
        for enclosure_node in atom_enclosures
          enclosure_url = FeedTools::HtmlHelper.unescape_entities(
            enclosure_node.attributes["href"].to_s)
          enclosure = nil
          new_enclosure = false
          for existing_enclosure in @enclosures
            if existing_enclosure.url == enclosure_url
              enclosure = existing_enclosure
              break
            end
          end
          if enclosure.nil?
            new_enclosure = true
            enclosure = FeedTools::Enclosure.new
          end
          enclosure.url = enclosure_url
          enclosure.type = enclosure_node.attributes["type"].to_s
          enclosure.file_size = enclosure_node.attributes["length"].to_i
          enclosure.credits = []
          enclosure.explicit = false
          if new_enclosure
            @enclosures << enclosure
          end
        end
        
        # Parse atom-type enclosures.  If there are repeats of the same
        # enclosure object, we merge the two together.
        for enclosure_node in bogus_enclosures
          enclosure_url = FeedTools::HtmlHelper.unescape_entities(
            enclosure_node.attributes["url"].to_s)
          enclosure = nil
          new_enclosure = false
          for existing_enclosure in @enclosures
            if existing_enclosure.url == enclosure_url
              enclosure = existing_enclosure
              break
            end
          end
          if enclosure.nil?
            new_enclosure = true
            enclosure = FeedTools::Enclosure.new
          end
          enclosure.url = enclosure_url
          if File.extname(enclosure_url) == ".wmv"
            enclosure.type = "video/x-ms-wmv"
          end
          enclosure.explicit = false
          if new_enclosure
            @enclosures << enclosure
          end
        end

        # Creates an anonymous method to parse content objects from the media
        # module.  We do this to avoid excessive duplication of code since we
        # have to do identical processing for content objects within group
        # objects.
        parse_media_content = lambda do |media_content_nodes|
          affected_enclosures = []
          for enclosure_node in media_content_nodes
            enclosure_url = FeedTools::HtmlHelper.unescape_entities(
              enclosure_node.attributes["url"].to_s)
            enclosure = nil
            new_enclosure = false
            for existing_enclosure in @enclosures
              if existing_enclosure.url == enclosure_url
                enclosure = existing_enclosure
                break
              end
            end
            if enclosure.nil?
              new_enclosure = true
              enclosure = FeedTools::Enclosure.new
            end
            enclosure.url = enclosure_url
            enclosure.type = enclosure_node.attributes["type"].to_s
            enclosure.file_size = enclosure_node.attributes["fileSize"].to_i
            enclosure.duration = enclosure_node.attributes["duration"].to_s
            enclosure.height = enclosure_node.attributes["height"].to_i
            enclosure.width = enclosure_node.attributes["width"].to_i
            enclosure.bitrate = enclosure_node.attributes["bitrate"].to_i
            enclosure.framerate = enclosure_node.attributes["framerate"].to_i
            enclosure.expression =
              enclosure_node.attributes["expression"].to_s
            enclosure.is_default =
              (enclosure_node.attributes["isDefault"].to_s.downcase == "true")
            enclosure_thumbnail_url = FeedTools::XmlHelper.try_xpaths(enclosure_node,
              ["media:thumbnail/@url"], :select_result_value => true)
            if !enclosure_thumbnail_url.blank?
              enclosure.thumbnail = FeedTools::EnclosureThumbnail.new(
                FeedTools::HtmlHelper.unescape_entities(enclosure_thumbnail_url),
                FeedTools::HtmlHelper.unescape_entities(
                  FeedTools::XmlHelper.try_xpaths(enclosure_node, ["media:thumbnail/@height"],
                    :select_result_value => true)),
                FeedTools::HtmlHelper.unescape_entities(
                  FeedTools::XmlHelper.try_xpaths(enclosure_node, ["media:thumbnail/@width"],
                    :select_result_value => true))
              )
            end
            enclosure.categories = []
            for category in FeedTools::XmlHelper.try_xpaths_all(enclosure_node, ["media:category"])
              enclosure.categories << FeedTools::Category.new
              enclosure.categories.last.term =
                FeedTools::HtmlHelper.unescape_entities(category.inner_xml)
              enclosure.categories.last.scheme =
                FeedTools::HtmlHelper.unescape_entities(
                  category.attributes["scheme"].to_s)
              enclosure.categories.last.label =
                FeedTools::HtmlHelper.unescape_entities(
                  category.attributes["label"].to_s)
              if enclosure.categories.last.scheme.blank?
                enclosure.categories.last.scheme = nil
              end
              if enclosure.categories.last.label.blank?
                enclosure.categories.last.label = nil
              end
            end
            enclosure_media_hash = FeedTools::XmlHelper.try_xpaths(enclosure_node,
              ["media:hash/text()"], :select_result_value => true)
            if !enclosure_media_hash.nil?
              enclosure.hash = FeedTools::EnclosureHash.new(
                FeedTools::HtmlHelper.sanitize_html(FeedTools::HtmlHelper.unescape_entities(
                  enclosure_media_hash), :strip),
                "md5"
              )
            end
            enclosure_media_player_url = FeedTools::XmlHelper.try_xpaths(enclosure_node,
              ["media:player/@url"], :select_result_value => true)
            if !enclosure_media_player_url.blank?
              enclosure.player = FeedTools::EnclosurePlayer.new(
                FeedTools::HtmlHelper.unescape_entities(enclosure_media_player_url),
                FeedTools::HtmlHelper.unescape_entities(
                  FeedTools::XmlHelper.try_xpaths(enclosure_node,
                    ["media:player/@height"], :select_result_value => true)),
                FeedTools::HtmlHelper.unescape_entities(
                  FeedTools::XmlHelper.try_xpaths(enclosure_node,
                    ["media:player/@width"], :select_result_value => true))
              )
            end
            enclosure.credits = []
            for credit in FeedTools::XmlHelper.try_xpaths_all(enclosure_node, ["media:credit"])
              enclosure.credits << FeedTools::EnclosureCredit.new(
                FeedTools::HtmlHelper.unescape_entities(credit.inner_xml.to_s.strip),
                FeedTools::HtmlHelper.unescape_entities(
                  credit.attributes["role"].to_s.downcase)
              )
              if enclosure.credits.last.name.blank?
                enclosure.credits.last.name = nil
              end
              if enclosure.credits.last.role.blank?
                enclosure.credits.last.role = nil
              end
            end
            enclosure.explicit = (FeedTools::XmlHelper.try_xpaths(enclosure_node,
              ["media:adult/text()"]).to_s.downcase == "true")
            enclosure_media_text =
              FeedTools::XmlHelper.try_xpaths(enclosure_node, ["media:text/text()"])
            if !enclosure_media_text.blank?
              enclosure.text = FeedTools::HtmlHelper.unescape_entities(
                enclosure_media_text)
            end
            affected_enclosures << enclosure
            if new_enclosure
              @enclosures << enclosure
            end
          end
          affected_enclosures
        end
        
        # Parse the independant content objects.
        parse_media_content.call(media_content_enclosures)
        
        media_groups = []
        
        # Parse the group objects.
        for media_group in media_group_enclosures
          group_media_content_enclosures =
            FeedTools::XmlHelper.try_xpaths_all(media_group, ["media:content"])
          
          # Parse the content objects within the group objects.
          affected_enclosures =
            parse_media_content.call(group_media_content_enclosures)
          
          # Now make sure that content objects inherit certain properties from
          # the group objects.
          for enclosure in affected_enclosures
            media_group_thumbnail = FeedTools::XmlHelper.try_xpaths(media_group,
              ["media:thumbnail/@url"], :select_result_value => true)
            if enclosure.thumbnail.nil? && !media_group_thumbnail.blank?
              enclosure.thumbnail = FeedTools::EnclosureThumbnail.new(
                FeedTools::HtmlHelper.unescape_entities(
                  media_group_thumbnail),
                FeedTools::HtmlHelper.unescape_entities(
                  FeedTools::XmlHelper.try_xpaths(media_group, ["media:thumbnail/@height"],
                    :select_result_value => true)),
                FeedTools::HtmlHelper.unescape_entities(
                  FeedTools::XmlHelper.try_xpaths(media_group, ["media:thumbnail/@width"],
                    :select_result_value => true))
              )
            end
            if (enclosure.categories.blank?)
              enclosure.categories = []
              for category in FeedTools::XmlHelper.try_xpaths_all(media_group, ["media:category"])
                enclosure.categories << FeedTools::Category.new
                enclosure.categories.last.term =
                  FeedTools::HtmlHelper.unescape_entities(category.inner_xml)
                enclosure.categories.last.scheme =
                  FeedTools::HtmlHelper.unescape_entities(
                    category.attributes["scheme"].to_s)
                enclosure.categories.last.label =
                  FeedTools::HtmlHelper.unescape_entities(
                    category.attributes["label"].to_s)
                if enclosure.categories.last.scheme.blank?
                  enclosure.categories.last.scheme = nil
                end
                if enclosure.categories.last.label.blank?
                  enclosure.categories.last.label = nil
                end
              end
            end
            enclosure_media_group_hash = FeedTools::XmlHelper.try_xpaths(enclosure_node,
              ["media:hash/text()"], :select_result_value => true)
            if enclosure.hash.nil? && !enclosure_media_group_hash.blank?
              enclosure.hash = FeedTools::EnclosureHash.new(
                FeedTools::HtmlHelper.sanitize_html(FeedTools::HtmlHelper.unescape_entities(
                  enclosure_media_group_hash), :strip),
                "md5"
              )
            end
            enclosure_media_group_url = FeedTools::XmlHelper.try_xpaths(media_group,
              "media:player/@url", :select_result_value => true)
            if enclosure.player.nil? && !enclosure_media_group_url.blank?
              enclosure.player = FeedTools::EnclosurePlayer.new(
                FeedTools::HtmlHelper.unescape_entities(enclosure_media_group_url),
                FeedTools::HtmlHelper.unescape_entities(
                  FeedTools::XmlHelper.try_xpaths(media_group, ["media:player/@height"],
                    :select_result_value => true)),
                FeedTools::HtmlHelper.unescape_entities(
                  FeedTools::XmlHelper.try_xpaths(media_group, ["media:player/@width"],
                    :select_result_value => true))
              )
            end
            if enclosure.credits.nil? || enclosure.credits.size == 0
              enclosure.credits = []
              for credit in FeedTools::XmlHelper.try_xpaths_all(media_group, ["media:credit"])
                enclosure.credits << FeedTools::EnclosureCredit.new(
                  FeedTools::HtmlHelper.unescape_entities(credit.inner_xml),
                  FeedTools::HtmlHelper.unescape_entities(
                    credit.attributes["role"].to_s.downcase)
                )
                if enclosure.credits.last.role.blank?
                  enclosure.credits.last.role = nil
                end
              end
            end
            if enclosure.explicit?.nil?
              enclosure.explicit = ((FeedTools::XmlHelper.try_xpaths(media_group, [
                "media:adult/text()"
              ], :select_result_value => true).downcase == "true") ?
                true : false)
            end
            enclosure_media_group_text = FeedTools::XmlHelper.try_xpaths(media_group,
              ["media:text/text()"], :select_result_value => true)
            if enclosure.text.nil? && !enclosure_media_group_text.blank?
              enclosure.text = FeedTools::HtmlHelper.sanitize_html(
                FeedTools::HtmlHelper.unescape_entities(
                  enclosure_media_group_text), :strip)
            end
          end
          
          # Keep track of the media groups
          media_groups << affected_enclosures
        end
        
        # Now we need to inherit any relevant item level information.
        if self.explicit?
          for enclosure in @enclosures
            enclosure.explicit = true
          end
        end
        
        # Add all the itunes categories
        itunes_categories =
          FeedTools::XmlHelper.try_xpaths_all(self.root_node, ["itunes:category"])
        for itunes_category in itunes_categories
          genre = "Podcasts"
          category = itunes_category.attributes["text"].to_s
          subcategory =
            FeedTools::XmlHelper.try_xpaths(itunes_category, ["itunes:category/@text"],
              :select_result_value => true)
          category_path = genre
          if !category.blank?
            category_path << "/" + category
          end
          if !subcategory.blank?
            category_path << "/" + subcategory
          end          
          for enclosure in @enclosures
            if enclosure.categories.nil?
              enclosure.categories = []
            end
            enclosure.categories << FeedTools::Category.new
            enclosure.categories.last.term =
              FeedTools::HtmlHelper.unescape_entities(category_path)
            enclosure.categories.last.scheme =
              "http://www.apple.com/itunes/store/"
            enclosure.categories.last.label =
              "iTunes Music Store Categories"
          end
        end

        for enclosure in @enclosures
          # Clean up any of those attributes that incorrectly have ""
          # or 0 as their values        
          if enclosure.type.blank?
            enclosure.type = nil
          end
          if enclosure.file_size == 0
            enclosure.file_size = nil
          end
          if enclosure.duration == 0
            enclosure.duration = nil
          end
          if enclosure.height == 0
            enclosure.height = nil
          end
          if enclosure.width == 0
            enclosure.width = nil
          end
          if enclosure.bitrate == 0
            enclosure.bitrate = nil
          end
          if enclosure.framerate == 0
            enclosure.framerate = nil
          end
          if enclosure.expression.blank?
            enclosure.expression = "full"
          end

          # If an enclosure is missing the text field, fall back on the
          # itunes:summary field
          if enclosure.text.blank?
            enclosure.text = self.itunes_summary
          end

          # Make sure we don't have duplicate categories
          unless enclosure.categories.nil?
            enclosure.categories.uniq!
          end
          
          # Normalize enclosure URIs
          if !enclosure.href.blank?
            enclosure.href =
              FeedTools::UriHelper.normalize_url(enclosure.href)
          else
            enclosure.href = nil
          end
        end
        
        # And finally, now things get complicated.  This is where we make
        # sure that the enclosures method only returns either default
        # enclosures or enclosures with only one version.  Any enclosures
        # that are wrapped in a media:group will be placed in the appropriate
        # versions field.
        affected_enclosure_urls = []
        for media_group in media_groups
          affected_enclosure_urls =
            affected_enclosure_urls | (media_group.map do |enclosure|
              enclosure.url
            end)
        end
        @enclosures.delete_if do |enclosure|
          (affected_enclosure_urls.include? enclosure.url)
        end
        for media_group in media_groups
          default_enclosure = nil
          for enclosure in media_group
            if enclosure.is_default?
              default_enclosure = enclosure
            end
          end
          for enclosure in media_group
            enclosure.default_version = default_enclosure
            enclosure.versions = media_group.clone
            enclosure.versions.delete(enclosure)
          end
          @enclosures << default_enclosure
        end
      end

      # If we have a single enclosure, it's safe to inherit the
      # itunes:duration field if it's missing.
      if @enclosures.size == 1
        if @enclosures.first.duration.nil? || @enclosures.first.duration == 0
          @enclosures.first.duration = self.itunes_duration
        end
      end

      return @enclosures
    end
    
    def enclosures=(new_enclosures)
      @enclosures = new_enclosures
    end
    
    # Returns the feed item author
    def author
      if @author.nil?
        @author = FeedTools::Author.new
        author_node = FeedTools::XmlHelper.try_xpaths(self.root_node, [
          "atom10:author",
          "atom03:author",
          "atom:author",
          "author",
          "managingEditor",
          "dc:author",
          "dc:creator",
          "creator"
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
                "@url",
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
        if @author.name.blank? && @author.email.blank? &&
            @author.href.blank?
          parent_feed = self.feed
          if parent_feed != nil
            @author = parent_feed.author.dup
          end
        end
      end
      return @author
    end
    
    # Sets the feed item author
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

        # Set the author name
        @publisher.raw = FeedTools::HtmlHelper.unescape_entities(
          FeedTools::XmlHelper.try_xpaths(self.root_node, [
            "dc:publisher/text()",
            "webMaster/text()"
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
              root_base_uri = nil
              unless self.root_node.nil?
                root_base_uri = self.root_node.base_uri
              end
              @publisher.url = FeedTools::UriHelper.resolve_relative_uri(
                @publisher.url, [root_base_uri, self.base_uri])
            end
          rescue
          end
        end
        if @publisher.name.blank? && @publisher.email.blank? &&
            @publisher.href.blank?
          parent_feed = self.feed
          if parent_feed != nil
            @publisher = parent_feed.publisher.dup
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
    # This inherits from any incorrectly placed channel-level itunes:author
    # elements.  They're actually amazingly common.  People don't read specs.
    def itunes_author
      if @itunes_author.nil?
        @itunes_author = FeedTools::HtmlHelper.unescape_entities(
          FeedTools::XmlHelper.try_xpaths(self.root_node,
            ["itunes:author/text()"], :select_result_value => true))
        if @itunes_author.blank?
          parent_feed = self.feed
          if parent_feed != nil
            @itunes_author = parent_feed.itunes_author
          end
        end
      end
      return @itunes_author
    end

    # Sets the contents of the itunes:author element
    def itunes_author=(new_itunes_author)
      @itunes_author = new_itunes_author
    end        
        
    # Returns the number of seconds that the associated media runs for
    def itunes_duration
      if @itunes_duration.nil?
        raw_duration = FeedTools::HtmlHelper.unescape_entities(
          FeedTools::XmlHelper.try_xpaths(self.root_node,
            ["itunes:duration/text()"], :select_result_value => true))
        if !raw_duration.blank?
          hms = raw_duration.split(":").map { |x| x.to_i }
          if hms.size == 3
            @itunes_duration = hms[0].hours + hms[1].minutes + hms[2]
          elsif hms.size == 2
            @itunes_duration = hms[0].minutes + hms[1]
          elsif hms.size == 1
            @itunes_duration = hms[0]
          end
        end
      end
      return @itunes_duration
    end
    
    # Sets the number of seconds that the associate media runs for
    def itunes_duration=(new_itunes_duration)
      @itunes_duration = new_itunes_duration
    end
    
    # Returns the feed item time
    def time(options = {})
      FeedTools::GenericHelper.validate_options([ :estimate_timestamp ],
                       options.keys)
      options = { :estimate_timestamp => true }.merge(options)
      if @time.nil?
        time_string = FeedTools::XmlHelper.try_xpaths(self.root_node, [
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
          "date/text()",
          "lastupdated/text()"
        ], :select_result_value => true)
        begin
          if !time_string.blank?
            @time = Time.parse(time_string).gmtime
          elsif self.configurations[:timestamp_estimation_enabled] &&
              !self.title.nil? &&
              (Time.parse(self.title) - Time.now).abs > 100
            @time = Time.parse(self.title).gmtime
          end
        rescue
        end
        if self.configurations[:timestamp_estimation_enabled]
          if options[:estimate_timestamp]
            if @time.nil?
              begin
                @time = succ_time
                if @time.nil?
                  @time = prev_time
                end
              rescue
              end
              if @time.nil?
                @time = Time.now.gmtime
              end
            end
          end
        end
      end
      return @time
    end
    
    # Sets the feed item time
    def time=(new_time)
      @time = new_time
    end
    
    # Returns 1 second after the previous item's time.
    def succ_time #:nodoc:
      begin
        parent_feed = self.feed
        if parent_feed.nil?
          return nil
        end
        if parent_feed.instance_variable_get("@entries").nil?
          parent_feed.items
        end
        unsorted_items = parent_feed.instance_variable_get("@entries")
        item_index = unsorted_items.index(self)
        if item_index.nil?
          return nil
        end
        if item_index <= 0
          return nil
        end
        previous_item = unsorted_items[item_index - 1]
        return (previous_item.time(:estimate_timestamp => false) + 1)
      rescue
        return nil
      end
    end
    private :succ_time

    # Returns 1 second before the succeeding item's time.
    def prev_time #:nodoc:
      begin
        parent_feed = self.feed
        if parent_feed.nil?
          return nil
        end
        if parent_feed.instance_variable_get("@entries").nil?
          parent_feed.items
        end
        unsorted_items = parent_feed.instance_variable_get("@entries")
        item_index = unsorted_items.index(self)
        if item_index.nil?
          return nil
        end
        if item_index >= (unsorted_items.size - 1)
          return nil
        end
        succeeding_item = unsorted_items[item_index + 1]
        return (succeeding_item.time(:estimate_timestamp => false) - 1)
      rescue
        return nil
      end
    end
    private :prev_time
    
    # Returns the feed item updated time
    def updated
      if @updated.nil?
        updated_string = FeedTools::XmlHelper.try_xpaths(self.root_node, [
          "atom10:updated/text()",
          "atom03:updated/text()",
          "atom:updated/text()",
          "updated/text()",
          "atom10:modified/text()",
          "atom03:modified/text()",
          "atom:modified/text()",
          "modified/text()",
          "lastBuildDate/text()",
          "lastupdated/text()"
        ], :select_result_value => true)
        if !updated_string.blank?
          @updated = Time.parse(updated_string).gmtime rescue nil
        else
          @updated = nil
        end
      end
      return @updated
    end
    
    # Sets the feed item updated time
    def updated=(new_updated)
      @updated = new_updated
    end

    # Returns the feed item published time
    def published
      if @published.nil?
        published_string = FeedTools::XmlHelper.try_xpaths(self.root_node, [
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
        if !published_string.blank?
          @published = Time.parse(published_string).gmtime rescue nil
        else
          @published = nil
        end
      end
      return @published
    end
    
    # Sets the feed item published time
    def published=(new_published)
      @published = new_published
    end
    
    # TODO: FIX ME!  This code is completely wrong.
    # The source that this post was based on
    def source
      if @source.nil?
        @source = FeedTools::Link.new
        @source.href = FeedTools::XmlHelper.try_xpaths(
          self.root_node, ["source/@url"],
          :select_result_value => true)
        @source.title = FeedTools::XmlHelper.try_xpaths(
          self.root_node, ["source/text()"],
          :select_result_value => true)
      end
      return @source
    end
        
    # Returns the feed item tags
    def tags
      # TODO: support the rel="tag" microformat
      # =======================================
      if @tags.nil?
        @tags = []
        if root_node.nil?
          return @tags
        end
        if @tags.nil? || @tags.size == 0
          @tags = []
          tag_list = FeedTools::XmlHelper.try_xpaths_all(self.root_node,
            ["dc:subject/rdf:Bag/rdf:li/text()"],
            :select_result_value => true)
          if tag_list != nil && tag_list.size > 0
            for tag in tag_list
              @tags << tag.downcase.strip
            end
          end
        end
        if @tags.nil? || @tags.size == 0
          # messy effort to find ourselves some tags, mainly for del.icio.us
          @tags = []
          rdf_bag = FeedTools::XmlHelper.try_xpaths_all(self.root_node,
            ["taxo:topics/rdf:Bag/rdf:li"])
          if rdf_bag != nil && rdf_bag.size > 0
            for tag_node in rdf_bag
              begin
                tag_url = FeedTools::XmlHelper.try_xpaths(tag_node, ["@resource"],
                  :select_result_value => true)
                tag_match = tag_url.scan(/\/(tag|tags)\/(\w+)$/)
                if tag_match.size > 0
                  @tags << tag_match.first.last.downcase.strip
                end
              rescue
              end
            end
          end
        end
        if @tags.nil? || @tags.size == 0
          @tags = []
          tag_list = FeedTools::XmlHelper.try_xpaths_all(self.root_node, ["category/text()"],
            :select_result_value => true)
          for tag in tag_list
            @tags << tag.to_s.downcase.strip
          end
        end
        if @tags.nil? || @tags.size == 0
          @tags = []
          tag_list = FeedTools::XmlHelper.try_xpaths_all(self.root_node, ["dc:subject/text()"],
            :select_result_value => true)
          for tag in tag_list
            @tags << tag.to_s.downcase.strip
          end
        end
        if @tags.blank?
          begin
            itunes_keywords_string = FeedTools::XmlHelper.try_xpaths(self.root_node, [
              "itunes:keywords/text()"
            ], :select_result_value => true)
            unless itunes_keywords_string.blank?
              @tags = itunes_keywords_string.downcase.split(",")
              if @tags.size == 1
                @tags = itunes_keywords_string.downcase.split(" ")
                @tags = @tags.map { |tag| tag.chomp(",") }
              end
              if @tags.size == 1
                @tags = itunes_keywords_string.downcase.split(",")
              end
              @tags = @tags.map { |tag| tag.strip }
            end
          rescue
            @tags = []
          end
        end
        if @tags.nil?
          @tags = []
        end
        @tags.uniq!
      end
      return @tags
    end
    
    # Sets the feed item tags
    def tags=(new_tags)
      @tags = new_tags
    end
    
    # Returns true if this feed item contains explicit material.  If the whole
    # feed has been marked as explicit, this will return true even if the item
    # isn't explicitly marked as explicit.
    def explicit?
      if @explicit.nil?
        explicit_string = FeedTools::XmlHelper.try_xpaths(self.root_node, [
          "media:adult/text()",
          "itunes:explicit/text()"
        ], :select_result_value => true)
        parent_feed = self.feed
        if explicit_string == "true" || explicit_string == "yes"
          @explicit = true
        elsif parent_feed != nil && parent_feed.explicit?
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
    
    # A hook method that is called during the feed generation process.  Overriding this method
    # will enable additional content to be inserted into the feed.
    def build_xml_hook(feed_type, version, xml_builder)
      return nil
    end

    # Generates xml based on the content of the feed item
    def build_xml(feed_type=(self.feed.feed_type or "atom"), version=nil,
        xml_builder=Builder::XmlMarkup.new(
          :indent => 2, :escape_attrs => false))
          
      parent_feed = self.feed
      if parent_feed.find_node(
          "access:restriction/@relationship").to_s == "deny"
        raise StandardError,
          "Operation not permitted.  This feed denies redistribution."
      elsif parent_feed.find_node("@indexing:index").to_s == "no"
        raise StandardError,
          "Operation not permitted.  This feed denies redistribution."
      end
      if self.find_node(
          "access:restriction/@relationship").to_s == "deny"
        raise StandardError,
          "Operation not permitted.  This feed item denies redistribution."
      end
      
      self.full_parse()
      
      if feed_type == "rss" && (version == nil || version == 0.0)
        version = 1.0
      elsif feed_type == "atom" && (version == nil || version == 0.0)
        version = 1.0
      end
      if feed_type == "rss" && (version == 0.9 || version == 1.0 || version == 1.1)
        # RDF-based rss format
        if link.nil?
          raise "Cannot generate an rdf-based feed item with a nil link field."
        end
        return xml_builder.item("rdf:about" =>
            FeedTools::HtmlHelper.escape_entities(link)) do
          unless self.title.blank?
            xml_builder.title(FeedTools::HtmlHelper.strip_html_tags(self.title))
          else
            xml_builder.title
          end
          unless self.link.blank?
            xml_builder.link(self.link)
          else
            xml_builder.link
          end
          unless self.author.nil? || self.author.name.nil?
            xml_builder.tag!("dc:creator", self.author.name)
          end
          unless self.summary.blank?
            xml_builder.description(self.summary)
          else
            xml_builder.description
          end
          unless self.content.blank?
            xml_builder.tag!("content:encoded") do
              xml_builder.cdata!(self.content)
            end
          end
          unless time.nil?
            xml_builder.tag!("dc:date", time.iso8601)            
          end
          unless self.rights.blank?
            xml_builder.tag!("dc:rights", self.rights)
          end
          unless tags.nil? || tags.size == 0
            for tag in tags
              xml_builder.tag!("dc:subject", tag)
            end
            if self.feed.podcast?
              xml_builder.tag!("itunes:keywords", tags.join(", "))
            end
          end
          build_xml_hook(feed_type, version, xml_builder)
        end
      elsif feed_type == "rss"
        # normal rss format
        return xml_builder.item do
          unless self.title.blank?
            xml_builder.title(FeedTools::HtmlHelper.strip_html_tags(self.title))
          end
          unless self.link.blank?
            xml_builder.link(self.link)
          end
          unless self.author.nil? || self.author.name.nil?
            xml_builder.tag!("dc:creator", self.author.name)
          end
          unless self.author.nil? || self.author.email.nil? ||
              self.author.name.nil?
            xml_builder.author("#{self.author.email} (#{self.author.name})")
          end
          unless self.summary.blank?
            xml_builder.description(self.summary)
          end
          unless self.content.blank?
            xml_builder.tag!("content:encoded") do
              xml_builder.cdata!(self.content)
            end
          end
          if !self.published.nil?
            xml_builder.pubDate(self.published.rfc822)            
          elsif !self.time.nil?
            xml_builder.pubDate(self.time.rfc822)            
          end
          unless self.copyright.blank?
            xml_builder.tag!("dc:rights", self.copyright)
          end
          unless self.guid.blank?
            if FeedTools::UriHelper.is_uri?(self.guid) && (self.guid =~ /^http/)
              xml_builder.guid(self.guid, "isPermaLink" => "true")
            else
              xml_builder.guid(self.guid, "isPermaLink" => "false")
            end
          else
            unless self.link.blank?
              xml_builder.guid(self.link, "isPermaLink" => "true")
            end
          end
          unless tags.nil? || tags.size == 0
            for tag in tags
              xml_builder.tag!("category", tag)
            end
            if self.feed.podcast?
              xml_builder.tag!("itunes:keywords", tags.join(", "))
            end
          end
          unless self.enclosures.blank? || self.enclosures.size == 0
            for enclosure in self.enclosures
              attribute_hash = {}
              next if enclosure.url.blank?
              begin
                if enclosure.file_size.blank? || enclosure.file_size.to_i == 0
                  # We can't use this enclosure because it's missing the
                  # required file size.  Check alternate versions for
                  # file_size.
                  if !enclosure.versions.blank? && enclosure.versions.size > 0
                    for alternate in enclosure.versions
                      if alternate.file_size != nil &&
                          alternate.file_size.to_i > 0
                        enclosure = alternate
                        break
                      end
                    end
                  end
                end
              rescue
              end
              attribute_hash["url"] = FeedTools::UriHelper.normalize_url(enclosure.url)
              if enclosure.type != nil
                attribute_hash["type"] = enclosure.type
              end
              if enclosure.file_size != nil && enclosure.file_size.to_i > 0
                attribute_hash["length"] = enclosure.file_size.to_s
              else
                # We couldn't find an alternate and the problem is still
                # there.  Give up and go on.
                xml_builder.comment!(
                  "*** Enclosure failed to include file size. Ignoring. ***")
                next
              end
              xml_builder.enclosure(attribute_hash)
            end
          end
          build_xml_hook(feed_type, version, xml_builder)
        end
      elsif feed_type == "atom" && version == 0.3
        raise "Atom 0.3 is obsolete."
      elsif feed_type == "atom" && version == 1.0
        # normal atom format
        return xml_builder.entry("xmlns" =>
            FEED_TOOLS_NAMESPACES['atom10']) do
          unless title.nil? || title == ""
            xml_builder.title(
              FeedTools::HtmlHelper.strip_html_tags(self.title),
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
          unless link.nil? || link == ""
            xml_builder.link(
                "href" =>
                  FeedTools::HtmlHelper.escape_entities(self.link),
                "rel" => "alternate")
          end
          if !self.content.blank?
            xml_builder.content(self.content,
                "type" => "html")
          end
          if !self.summary.blank?
            xml_builder.summary(self.summary,
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
          unless self.published.nil?
            xml_builder.published(self.published.iso8601)            
          end
          unless self.rights.blank?
            xml_builder.rights(self.rights)
          end
          if self.id != nil
            unless FeedTools::UriHelper.is_uri? self.id
              if self.time != nil && self.link != nil
                xml_builder.id(FeedTools::UriHelper.build_tag_uri(self.link, self.time))
              elsif self.link != nil
                xml_builder.id(FeedTools.build_urn_uuid_uri(self.link))
              else
                raise "The unique id must be a URI. " +
                  "(Attempted to generate id, but failed.)"
              end
            else
              xml_builder.id(self.id)
            end
          elsif self.time != nil && self.link != nil
            xml_builder.id(FeedTools::UriHelper.build_tag_uri(self.link, self.time))
          else
            raise "Cannot build feed, missing feed unique id."
          end
          unless self.tags.nil? || self.tags.size == 0
            for tag in self.tags
              xml_builder.category("term" => tag)
            end
          end
          unless self.enclosures.blank? || self.enclosures.size == 0
            for enclosure in self.enclosures
              attribute_hash = {}
              next if enclosure.url.blank?
              attribute_hash["rel"] = "enclosure"
              attribute_hash["href"] = FeedTools::UriHelper.normalize_url(enclosure.url)
              if enclosure.type != nil
                attribute_hash["type"] = enclosure.type
              end
              if enclosure.file_size != nil && enclosure.file_size.to_i > 0
                attribute_hash["length"] = enclosure.file_size.to_s
              end
              xml_builder.link(attribute_hash)
            end
          end
          build_xml_hook(feed_type, version, xml_builder)
        end
      else
        raise "Unsupported feed format/version."
      end
    end
    
    alias_method :abstract, :summary
    alias_method :abstract=, :summary=
    alias_method :description, :summary
    alias_method :description=, :summary=
    alias_method :copyright, :rights
    alias_method :copyright=, :rights=
    alias_method :guid, :id
    alias_method :guid=, :id=
    
    # Returns a simple representation of the feed item object's state.
    def inspect
      return "#<FeedTools::FeedItem:0x#{self.object_id.to_s(16)} " +
        "LINK:#{self.link}>"
    end
  end
end
