module FeedTools
  # This is an implementation of a URI parser based on RFC 3986.
  class URI
    # Raised if something other than a uri is supplied.
    class InvalidURIError < StandardError
    end
    # Raised if an invalid method option is supplied.
    class InvalidOptionError < StandardError
    end
    
    # Returns a URI object based on the parsed string.
    def self.parse(uri_string)
      return nil if uri_string.nil?
      
      # If a URI object is passed, just return itself.
      return uri_string if uri_string.kind_of?(self)
      
      uri_regex =
        /^(([^:\/?#]+):)?(\/\/([^\/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?/
      scan = uri_string.scan(uri_regex)
      fragments = scan[0]
      return nil if fragments.nil?
      scheme = fragments[1]
      authority = fragments[3]
      path = fragments[4]
      query = fragments[6]
      fragment = fragments[8]
      userinfo = nil
      host = nil
      port = nil
      if authority != nil
        userinfo = authority.scan(/^([^\[\]]*)@/).flatten[0]
        host = authority.gsub(/^([^\[\]]*)@/, "").gsub(/:([^:@\[\]]*?)$/, "")
        port = authority.scan(/:([^:@\[\]]*?)$/).flatten[0]
      end
      if port.nil? || port == ""
        port = nil
      end
      
      # WARNING: Not standards-compliant, but follows the theme
      # of Postel's law:
      #
      # Special exception for dealing with the retarded idea of the
      # feed pseudo-protocol.  Without this exception, the parser will read
      # the URI as having a blank port number, instead of as having a second
      # URI embedded within.  This exception translates these broken URIs
      # and instead treats the inner URI as opaque.
      if scheme == "feed" && host == "http"
        userinfo = nil
        host = nil
        port = nil
        path = authority + path
      end
      
      return URI.new(scheme, userinfo, host, port, path, query, fragment)
    end
    
    # Converts a path to a file protocol URI.  If the path supplied is
    # relative, it will be returned as a relative URI.  If the path supplied
    # is actually a URI, it will return the parsed URI.
    def self.convert_path(path)
      return nil if path.nil?
      
      converted_uri = path.strip
      if converted_uri.length > 0 && converted_uri[0..0] == "/"
        converted_uri = "file://" + converted_uri
      end
      if converted_uri.length > 0 &&
          converted_uri.scan(/^[a-zA-Z]:[\\\/]/).size > 0
        converted_uri = "file:///" + converted_uri
      end
      converted_uri.gsub!(/^file:\/*/i, "file:///")
      if converted_uri =~ /^file:/i
        # Adjust windows-style uris
        converted_uri.gsub!(/^file:\/\/\/([a-zA-Z])\|/i, 'file:///\1:')
        converted_uri.gsub!(/\\/, '/')
        converted_uri = self.parse(converted_uri).normalize
      else
        converted_uri = self.parse(converted_uri)
      end
      
      return converted_uri
    end
    
    # Joins several uris together.
    def self.join(*uris)
      uri_objects = uris.collect do |uri|
        uri.kind_of?(self) ? uri : self.parse(uri.to_s)
      end
      result = uri_objects.shift.dup
      for uri in uri_objects
        result.merge!(uri)
      end
      return result
    end
    
    # Correctly escapes a uri.
    def self.escape(uri)
      uri_object = uri.kind_of?(self) ? uri : self.parse(uri.to_s)
      return URI.new(
        uri_object.scheme,
        uri_object.userinfo,
        uri_object.host,
        uri_object.specified_port,
        self.normalize_escaping(uri_object.path),
        self.normalize_escaping(uri_object.query),
        self.normalize_escaping(uri_object.fragment)
      ).to_s
    end

    # Extracts uris from an arbitrary body of text.
    def self.extract(text, options={})
      defaults = {:base => nil, :parse => false} 
      options = defaults.merge(options)
      raise InvalidOptionError unless (options.keys - defaults.keys).empty?
      # This regular expression needs to be less forgiving or else it would
      # match virtually all text.  Which isn't exactly what we're going for.
      extract_regex = /((([a-z\+]+):)[^ \n\<\>\"\\]+[\w\/])/
      extracted_uris =
        text.scan(extract_regex).collect { |match| match[0] }
      sgml_extract_regex = /<[^>]+href=\"([^\"]+?)\"[^>]*>/
      sgml_extracted_uris =
        text.scan(sgml_extract_regex).collect { |match| match[0] }
      extracted_uris.concat(sgml_extracted_uris - extracted_uris)
      textile_extract_regex = /\".+?\":([^ ]+\/[^ ]+)[ \,\.\;\:\?\!\<\>\"]/i
      textile_extracted_uris =
        text.scan(textile_extract_regex).collect { |match| match[0] }
      extracted_uris.concat(textile_extracted_uris - extracted_uris)
      parsed_uris = []
      base_uri = nil
      if options[:base] != nil
        base_uri = options[:base] if options[:base].kind_of?(self)
        base_uri = self.parse(options[:base].to_s) if base_uri == nil
      end
      for uri_string in extracted_uris
        begin
          if base_uri == nil
            parsed_uris << self.parse(uri_string)
          else
            parsed_uris << (base_uri + self.parse(uri_string))
          end
        rescue Exception
          nil
        end
      end
      parsed_uris.reject! do |uri|
        (uri.scheme =~ /T\d+/ ||
         uri.scheme == "xmlns" ||
         uri.scheme == "xml" ||
         uri.scheme == "thr" ||
         uri.scheme == "this" ||
         uri.scheme == "float" ||
         uri.scheme == "user" ||
         uri.scheme == "username" ||
         uri.scheme == "out")
      end
      if options[:parse]
        return parsed_uris
      else
        return parsed_uris.collect { |uri| uri.to_s }
      end
    end
    
    # Creates a new uri object from component parts.  Passing nil for
    # any of these parameters is acceptable.
    def initialize(scheme, userinfo, host, port, path, query, fragment)
      assign_components(scheme, userinfo, host, port, path, query, fragment)
    end
    
    # Returns the scheme (protocol) for this URI.
    def scheme
      return nil if @scheme.nil? || @scheme.strip == ""
      return @scheme
    end
    
    # Returns the username and password segment of this URI.
    def userinfo
      return @userinfo
    end
    
    # Returns the host for this URI.
    def host
      return @host
    end
    
    # Returns the authority segment of this URI.
    def authority
      if !defined?(@authority) || @authority.nil?
        return nil if self.host.nil?
        @authority = ""
        if self.userinfo != nil
          @authority << "#{self.userinfo}@"
        end
        @authority << self.host
        if self.specified_port != nil
          @authority << ":#{self.specified_port}"
        end
      end
      return @authority
    end
    
    # Returns the user for this URI.
    def user
      if !defined?(@user) || @user.nil?
        @user = nil
        return @user if @userinfo.nil?
        @user = @userinfo.strip.scan(/^(.*):/).flatten[0].strip
      end
      return @user
    end
    
    # Returns the password for this URI.
    def password
      if !defined?(@password) || @password.nil?
        @password = nil
        return @password if @userinfo.nil?
        @password = @userinfo.strip.scan(/:(.*)$/).flatten[0].strip
      end
      return @password
    end

    # Returns an array of known ip-based schemes.  These schemes typically
    # use a similar URI form:
    # //<user>:<password>@<host>:<port>/<url-path>
    def self.ip_based_schemes
      return self.scheme_mapping.keys
    end

    # Returns a hash of common IP-based schemes and their default port
    # numbers.  Adding new schemes to this hash, as necessary, will allow
    # for better URI normalization.
    def self.scheme_mapping
      if !defined?(@protocol_mapping) || @protocol_mapping.nil?
        @protocol_mapping = {
          "http" => 80,
          "https" => 443,
          "ftp" => 21,
          "tftp" => 69,
          "ssh" => 22,
          "svn+ssh" => 22,
          "telnet" => 23,
          "nntp" => 119,
          "gopher" => 70,
          "wais" => 210,
          "prospero" => 1525
        }
      end
      return @protocol_mapping
    end
    
    # Returns the port number for this URI.  This method will normalize to the
    # default port for the URI's scheme if the port isn't explicitly specified
    # in the URI.
    def port
      if @port.to_i == 0
        if self.scheme.nil?
          @port = nil
        else
          @port = self.class.scheme_mapping[self.scheme.strip.downcase]
        end
        return @port
      else
        @port = @port.to_i
        return @port
      end
    end
    
    # Returns the port number that was actually specified in the URI string.
    def specified_port
      @specified_port = nil if !defined?(@specified_port)
      return nil if @specified_port.nil?
      port = @specified_port.to_s.to_i
      if port == 0
        return nil
      else
        return port
      end
    end
    
    # Returns the path for this URI.
    def path
      return @path
    end
    
    # Returns the query string for this URI.
    def query
      return @query
    end
    
    # Returns the fragment for this URI.
    def fragment
      return @fragment
    end
    
    # Returns true if the URI uses an IP-based protocol.
    def ip_based?
      return false if self.scheme.nil?
      return self.class.ip_based_schemes.include?(self.scheme.strip.downcase)
    end
    
    # Returns true if this URI is known to be relative.
    def relative?
      return self.scheme.nil?
    end
    
    # Returns true if this URI is known to be absolute.
    def absolute?
      return !relative?
    end
    
    # Joins two URIs together.
    def +(uri)
      if !uri.kind_of?(self.class)
        uri = URI.parse(uri.to_s)
      end
      if uri.to_s == ""
        return self.dup
      end
      
      joined_scheme = nil
      joined_userinfo = nil
      joined_host = nil
      joined_port = nil
      joined_path = nil
      joined_query = nil
      joined_fragment = nil
      
      # Section 5.2.2 of RFC 3986
      if uri.scheme != nil
        joined_scheme = uri.scheme
        joined_userinfo = uri.userinfo
        joined_host = uri.host
        joined_port = uri.specified_port
        joined_path = self.class.normalize_path(uri.path)
        joined_query = uri.query
      else
        if uri.authority != nil
          joined_userinfo = uri.userinfo
          joined_host = uri.host
          joined_port = uri.specified_port
          joined_path = self.class.normalize_path(uri.path)
          joined_query = uri.query
        else
          if uri.path == nil || uri.path == ""
            joined_path = self.path
            if uri.query != nil
              joined_query = uri.query
            else
              joined_query = self.query
            end
          else
            if uri.path[0..0] == "/"
              joined_path = self.class.normalize_path(uri.path)
            else
              base_path = self.path.nil? ? "" : self.path.dup
              base_path = self.class.normalize_path(base_path)
              base_path.gsub!(/\/[^\/]+$/, "/")
              joined_path = self.class.normalize_path(base_path + uri.path)
            end
            joined_query = uri.query
          end
          joined_userinfo = self.userinfo
          joined_host = self.host
          joined_port = self.specified_port
        end
        joined_scheme = self.scheme
      end
      joined_fragment = uri.fragment
      
      return URI.new(
        joined_scheme,
        joined_userinfo,
        joined_host,
        joined_port,
        joined_path,
        joined_query,
        joined_fragment
      )
    end
    
    # Merges two URIs together.
    def merge(uri)
      return self + uri
    end
    
    # Destructive form of merge.
    def merge!(uri)
      replace_self(self.merge(uri))
    end
    
    # Returns a normalized URI object.
    #
    # NOTE: This method does not attempt to conform to specifications.  It
    # exists largely to correct other people's failures to read the
    # specifications, and also to deal with caching issues since several
    # different URIs may represent the same resource and should not be
    # cached multiple times.
    def normalize
      normalized_scheme = nil
      normalized_scheme = self.scheme.strip.downcase if self.scheme != nil
      normalized_scheme = "svn+ssh" if normalized_scheme == "ssh+svn"
      if normalized_scheme == "feed"
        if self.to_s =~ /^feed:\/*http:\/*/
          return self.class.parse(
            self.to_s.scan(/^feed:\/*(http:\/*.*)/).flatten[0]).normalize
        end
      end
      normalized_userinfo = nil
      normalized_userinfo = self.userinfo.strip if self.userinfo != nil
      normalized_host = nil
      normalized_host = self.host.strip.downcase if self.host != nil
      if normalized_host != nil
        begin
          normalized_host = URI::IDNA.to_ascii(normalized_host)
        rescue Exception
        end
      end
      
      # Normalize IPv4 addresses that were generated with the stupid
      # assumption that inet_addr() would be used to parse the IP address.
      if normalized_host != nil && normalized_host.strip =~ /^\d+$/
        # Decimal IPv4 address.
        decimal = normalized_host.to_i
        if decimal < (256 ** 4)
          octets = [0,0,0,0]
          octets[0] = decimal >> 24
          decimal -= (octets[0] * (256 ** 3))
          octets[1] = decimal >> 16
          decimal -= (octets[1] * (256 ** 2))
          octets[2] = decimal >> 8
          decimal -= (octets[2] * (256 ** 1))
          octets[3] = decimal
          normalized_host = octets.join(".")
        end
      elsif (normalized_host != nil && normalized_host.strip =~
          /^0+[0-7]{3}.0+[0-7]{3}.0+[0-7]{3}.0+[0-7]{3}$/)
        # Octal IPv4 address.
        octet_strings = normalized_host.split('.')
        octets = []
        octet_strings.each do |octet_string|
          decimal = octet_string.to_i(8)
          octets << decimal
        end
        normalized_host = octets.join(".")
      elsif (normalized_host != nil && normalized_host.strip =~
          /^0x[0-9a-f]{2}.0x[0-9a-f]{2}.0x[0-9a-f]{2}.0x[0-9a-f]{2}$/i)
        # Hexidecimal IPv4 address.
        octet_strings = normalized_host.split('.')
        octets = []
        octet_strings.each do |octet_string|
          decimal = octet_string[2...4].to_i(16)
          octets << decimal
        end
        normalized_host = octets.join(".")
      end
      normalized_port = self.port
      if self.class.scheme_mapping[normalized_scheme] == normalized_port
        normalized_port = nil
      end
      normalized_path = nil
      normalized_path = self.path.strip if self.path != nil
      if normalized_scheme != nil && normalized_host == nil
        if self.class.ip_based_schemes.include?(normalized_scheme) &&
            normalized_path =~ /[\w\.]+/
          normalized_host = normalized_path
          normalized_path = nil
          unless normalized_host =~ /\./
            normalized_host = normalized_host + ".com"
          end
        end
      end
      if normalized_path == nil &&
          normalized_scheme != nil &&
          normalized_host != nil
        normalized_path = "/"
      end
      if normalized_path != nil
        normalized_path = self.class.normalize_path(normalized_path)
        normalized_path = self.class.normalize_escaping(normalized_path)
      end
      if normalized_path == ""
        if ["http", "https", "ftp", "tftp"].include?(normalized_scheme)
          normalized_path = "/"
        end
      end
      normalized_path.gsub!(/%3B/, ";") if normalized_path != nil
      normalized_path.gsub!(/%3A/, ":") if normalized_path != nil
      normalized_path.gsub!(/%40/, "@") if normalized_path != nil
      normalized_path.gsub!(/%2B/, "+") if normalized_path != nil

      normalized_query = nil
      normalized_query = self.query.strip if self.query != nil
      normalized_query = self.class.normalize_escaping(normalized_query)
      normalized_query.gsub!(/%3D/, "=") if normalized_query != nil
      normalized_query.gsub!(/%26/, "&") if normalized_query != nil
      normalized_query.gsub!(/%2B/, "+") if normalized_query != nil
      
      normalized_fragment = nil
      normalized_fragment = self.fragment.strip if self.fragment != nil
      normalized_fragment = self.class.normalize_escaping(normalized_fragment)
      return URI.new(
        normalized_scheme,
        normalized_userinfo,
        normalized_host,
        normalized_port,
        normalized_path,
        normalized_query,
        normalized_fragment
      )
    end

    # Destructively normalizes this URI object.
    def normalize!
      replace_self(self.normalize)
    end
    
    # Creates a URI suitable for display to users.  If semantic attacks are
    # likely, the application should try to detect these and warn the user.
    # See RFC 3986 section 7.6 for more information.
    def display_uri
      display_uri = self.normalize
      begin
        display_uri.instance_variable_set("@host",
          URI::IDNA.to_unicode(display_uri.host))
      rescue Exception
      end
      return display_uri
    end
    
    # Returns true if the URI objects are equal.  This method normalizes
    # both URIs before doing the comparison, and allows comparison against
    # strings.
    def ===(uri)
      uri_string = nil
      if uri.respond_to?(:normalize)
        uri_string = uri.normalize.to_s
      else
        begin
          uri_string = URI.parse(uri.to_s).normalize.to_s
        rescue Exception
          return false
        end
      end
      return self.normalize.to_s == uri_string
    end
    
    # Returns true if the URI objects are equal.  This method normalizes
    # both URIs before doing the comparison.
    def ==(uri)
      return false unless uri.kind_of?(self.class) 
      return self.normalize.to_s == uri.normalize.to_s
    end

    # Returns true if the URI objects are equal.  This method does NOT
    # normalize either URI before doing the comparison.
    def eql?(uri)
      return false unless uri.kind_of?(self.class) 
      return self.to_s == uri.to_s
    end
    
    # Clones the URI object.
    def dup
      duplicated_scheme = nil
      duplicated_scheme = self.scheme.dup if self.scheme != nil
      duplicated_userinfo = nil
      duplicated_userinfo = self.userinfo.dup if self.userinfo != nil
      duplicated_host = nil
      duplicated_host = self.host.dup if self.host != nil
      duplicated_port = self.port
      duplicated_path = nil
      duplicated_path = self.path.dup if self.path != nil
      duplicated_query = nil
      duplicated_query = self.query.dup if self.query != nil
      duplicated_fragment = nil
      duplicated_fragment = self.fragment.dup if self.fragment != nil
      duplicated_uri = URI.new(
        duplicated_scheme,
        duplicated_userinfo,
        duplicated_host,
        duplicated_port,
        duplicated_path,
        duplicated_query,
        duplicated_fragment
      )
      @specified_port = nil if !defined?(@specified_port)
      duplicated_uri.instance_variable_set("@specified_port", @specified_port)
      return duplicated_uri
    end
    
    # Returns the assembled URI as a string.
    def to_s
      uri_string = ""
      if self.scheme != nil
        uri_string << "#{self.scheme}:"
      end
      if self.authority != nil
        uri_string << "//#{self.authority}"
      end
      if self.path != nil
        uri_string << self.path
      end
      if self.query != nil
        uri_string << "?#{self.query}"
      end
      if self.fragment != nil
        uri_string << "##{self.fragment}"
      end
      return uri_string
    end
    
    # Returns a string representation of the URI object's state.
    def inspect
      sprintf("#<%s:%#0x URL:%s>", self.class.to_s, self.object_id, self.to_s)
    end
    
    # This module handles internationalized domain names.  When Ruby has an
    # implementation of nameprep, stringprep, punycode, etc, this
    # module should contain an actual implementation of IDNA instead of
    # returning nil if libidn can't be used.
    module IDNA
      # Returns the ascii representation of the label.
      def self.to_ascii(label)
        return nil if label.nil?
        if self.use_libidn?
          return IDN::Idna.toASCII(label)
        else
          raise NotImplementedError,
            "There is no available pure-ruby implementation.  " +
            "Install libidn bindings."
        end
      end
      
      # Returns the unicode representation of the label.
      def self.to_unicode(label)
        return nil if label.nil?
        if self.use_libidn?
          return IDN::Idna.toUnicode(label)
        else
          raise NotImplementedError,
            "There is no available pure-ruby implementation.  " +
            "Install libidn bindings."
        end
      end
      
    private
      # Determines if the libidn bindings are available and able to be used.
      def self.use_libidn?
        if !defined?(@use_libidn) || @use_libidn.nil?
          begin
            require 'rubygems'
          rescue LoadError
          end
          begin
            require 'idn'
          rescue LoadError
          end
          @use_libidn = !!(defined?(IDN::Idna))
        end
        return @use_libidn
      end
    end
    
  private
    # Resolves paths to their simplest form.
    def self.normalize_path(path)
      return nil if path.nil?
      normalized_path = path.dup
      previous_state = normalized_path.dup
      begin
        previous_state = normalized_path.dup
        normalized_path.gsub!(/\/\.\//, "/")
        normalized_path.gsub!(/\/\.$/, "/")
        parent = normalized_path.scan(/\/([^\/]+)\/\.\.\//).flatten[0]
        if parent != "." && parent != ".."
          normalized_path.gsub!(/\/#{parent}\/\.\.\//, "/")
        end
        parent = normalized_path.scan(/\/([^\/]+)\/\.\.$/).flatten[0]
        if parent != "." && parent != ".."
          normalized_path.gsub!(/\/#{parent}\/\.\.$/, "/")
        end
        normalized_path.gsub!(/^\.\.?\/?/, "")
        normalized_path.gsub!(/^\/\.\.?\//, "/")
      end until previous_state == normalized_path
      return normalized_path
    end
    
    # Normalizes percent escaping of characters
    def self.normalize_escaping(escaped_section)
      return nil if escaped_section.nil?
      normalized_section = escaped_section.dup
      normalized_section.gsub!(/%[0-9a-f]{2}/i) do |sequence|
        sequence[1..3].to_i(16).chr
      end
      if URI::IDNA.send(:use_libidn?)
        normalized_section =
          IDN::Stringprep.nfkc_normalize(normalized_section)
      end
      new_section = ""
      for index in 0...normalized_section.size
        if self.unreserved?(normalized_section[index]) ||
            normalized_section[index] == '/'[0]
          new_section << normalized_section[index..index]
        else
          new_section << ("%" + normalized_section[index].to_s(16).upcase)
        end
      end
      normalized_section = new_section
      return normalized_section
    end
    
    # Returns true if the specified character is unreserved.
    def self.unreserved?(character)
      character_string = nil
      character_string = character.chr if character.respond_to?(:chr)
      character_string = character[0..0] if character.kind_of?(String)
      return self.unreserved.include?(character_string)
    end
    
    # Returns a list of unreserved characters.
    def self.unreserved
      if !defined?(@unreserved) || @unreserved.nil?
        @unreserved = ["-", ".", "_", "~"]
        for c in "a".."z"
          @unreserved << c
          @unreserved << c.upcase
        end
        for c in "0".."9"
          @unreserved << c
        end
        @unreserved.sort!
      end
      return @unreserved
    end
    
    # Assigns the specified components to the appropriate instance variables.
    # Used in destructive operations to avoid code repetition.
    def assign_components(scheme, userinfo, host, port, path, query, fragment)
      if scheme == nil && userinfo == nil && host == nil && port == nil &&
          path == nil && query == nil && fragment == nil
        raise InvalidURIError, "All parameters were nil."
      end
      @scheme = scheme
      @userinfo = userinfo
      @host = host
      @specified_port = port.to_s
      @port = port
      @port = @port.to_s if @port.kind_of?(Fixnum)
      if @port != nil && !(@port =~ /^\d+$/)
        raise InvalidURIError,
          "Invalid port number: #{@port.inspect}"
      end
      @port = @port.to_i
      @port = nil if @port == 0
      @path = path
      @query = query
      @fragment = fragment
      if @scheme != nil && @host == "" && @path == ""
        raise InvalidURIError,
          "Absolute URI missing hierarchical segment."
      end
    end
    
    # Replaces the internal state of self with the specified URI's state.
    # Used in destructive operations to avoid code repetition.
    def replace_self(uri)
      @authority = nil
      @user = nil
      @password = nil
      
      @scheme = uri.scheme
      @userinfo = uri.userinfo
      @host = uri.host
      @specified_port = uri.instance_variable_get("@specified_port")
      @port = @specified_port.to_s.to_i
      @path = uri.path
      @query = uri.query
      @fragment = uri.fragment
      return self
    end
  end
end