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

module FeedTools
  # Represents a feed/feed item's category
  class Category
  
    # The category term value
    attr_accessor :term
    # The categorization scheme
    attr_accessor :scheme
    # A human-readable description of the category
    attr_accessor :label
  
    alias_method :value, :term
    alias_method :category, :term
    alias_method :domain, :scheme
  end

  # Represents a feed/feed item's author
  class Author

    # The author's real name
    attr_accessor :name
    # The author's email address
    attr_accessor :email
    # The url of the author's homepage
    attr_accessor :href
    # The raw value of the author tag if present
    attr_accessor :raw

    alias_method :url, :href
    alias_method :url=, :href=
    alias_method :uri, :href
    alias_method :uri=, :href=
  end

  # Represents a feed's image
  class Image

    # The image's title
    attr_accessor :title
    # The image's description
    attr_accessor :description
    # The url of the image that is being linked to
    attr_accessor :href
    # The url to link the image to
    attr_accessor :link
    # The width of the image
    attr_accessor :width
    # The height of the image
    attr_accessor :height
    # The style of the image
    # Possible values are "icon", "image", or "image-wide"
    attr_accessor :style

    alias_method :url, :href
    alias_method :url=, :href=
  end

  # Represents a feed's text input element.
  # Be aware that this will be ignored for feed generation.  It's a
  # pointless element that aggregators usually ignore and it doesn't have an
  # equivalent in all feeds types.
  class TextInput

    # The label of the Submit button in the text input area.
    attr_accessor :title
    # The description explains the text input area.
    attr_accessor :description
    # The URL of the CGI script that processes text input requests.
    attr_accessor :link
    # The name of the text object in the text input area.
    attr_accessor :name
  end

  # Represents a feed's cloud.
  # Be aware that this will be ignored for feed generation.
  class Cloud

    # The domain of the cloud.
    attr_accessor :domain
    # The path for the cloud.
    attr_accessor :path
    # The port the cloud is listening on.
    attr_accessor :port
    # The web services protocol the cloud uses.
    # Possible values are either "xml-rpc" or "soap".
    attr_accessor :protocol
    # The procedure to use to request notification.
    attr_accessor :register_procedure
  end

  # Represents a simple hyperlink
  class Link
    # The url that is being linked to
    attr_accessor :href
    # The language of the resource being linked to
    attr_accessor :hreflang
    # The relation type of the link
    attr_accessor :rel
    # The mime type of the link
    attr_accessor :type    
    # The title of the hyperlink
    attr_accessor :title
    # The length of the resource being linked to in bytes
    attr_accessor :length
  
    alias_method :url, :href
    alias_method :url=, :href=
  end
  
  # This class stores information about a feed item's file enclosures.
  class Enclosure
    # The url for the enclosure
    attr_accessor :href
    # The MIME type of the file referenced by the enclosure
    attr_accessor :type
    # The size of the file referenced by the enclosure
    attr_accessor :file_size
    # The total play time of the file referenced by the enclosure
    attr_accessor :duration
    # The height in pixels of the enclosed media
    attr_accessor :height
    # The width in pixels of the enclosed media
    attr_accessor :width
    # The bitrate of the enclosed media
    attr_accessor :bitrate
    # The framerate of the enclosed media
    attr_accessor :framerate
    # The thumbnail for this enclosure
    attr_accessor :thumbnail
    # The categories for this enclosure
    attr_accessor :categories
    # A hash of the enclosed file
    attr_accessor :hash
    # A website containing some kind of media player instead of a direct
    # link to the media file.
    attr_accessor :player
    # A list of credits for the enclosed media
    attr_accessor :credits
    # A text rendition of the enclosed media
    attr_accessor :text
    # A list of alternate version of the enclosed media file
    attr_accessor :versions
    # The default version of the enclosed media file
    attr_accessor :default_version
  
    alias_method :url, :href
    alias_method :url=, :href=
    alias_method :link, :href
    alias_method :link=, :href=
    
    def initialize
      @expression = 'full'
    end
  
    # Returns true if this is the default enclosure
    def is_default?
      return @is_default
    end
  
    # Sets whether this is the default enclosure for the media group
    def is_default=(new_is_default)
      @is_default = new_is_default
    end
    
    # Returns true if the enclosure contains explicit material
    def explicit?
      return @explicit
    end
  
    # Sets the explicit attribute on the enclosure
    def explicit=(new_explicit)
      @explicit = new_explicit
    end
  
    # Determines if the object is a sample, or the full version of the
    # object, or if it is a stream.
    # Possible values are 'sample', 'full', 'nonstop'.
    def expression
      return @expression
    end
  
    # Sets the expression attribute on the enclosure.
    # Allowed values are 'sample', 'full', 'nonstop'.
    def expression=(new_expression)
      unless ['sample', 'full', 'nonstop'].include? new_expression.downcase
        return @expression
      end
      @expression = new_expression.downcase
    end
  
    # Returns true if this enclosure contains audio content
    def audio?
      unless self.type.nil?
        return true if (self.type =~ /^audio/) != nil
      end
      # TODO: create a more complete list
      # =================================
      audio_extensions = ['mp3', 'm4a', 'm4p', 'wav', 'ogg', 'wma']
      audio_extensions.each do |extension|
        if (url =~ /#{extension}$/) != nil
          return true
        end
      end
      return false
    end

    # Returns true if this enclosure contains video content
    def video?
      unless self.type.nil?
        return true if (self.type =~ /^video/) != nil
        return true if self.type == "image/mov"
      end
      # TODO: create a more complete list
      # =================================
      video_extensions = ['mov', 'mp4', 'avi', 'wmv', 'asf']
      video_extensions.each do |extension|
        if (url =~ /#{extension}$/) != nil
          return true
        end
      end
      return false
    end
  end

  # TODO: Make these actual classes instead of structs
  # ==================================================
  EnclosureHash = Struct.new( "EnclosureHash", :hash, :type )
  EnclosurePlayer = Struct.new( "EnclosurePlayer", :url, :height, :width )
  EnclosureCredit = Struct.new( "EnclosureCredit", :name, :role )
  EnclosureThumbnail = Struct.new( "EnclosureThumbnail", :url, :height,
    :width )
end