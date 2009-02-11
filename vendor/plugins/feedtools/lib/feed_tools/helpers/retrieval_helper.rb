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

require 'feed_tools'
require 'feed_tools/helpers/uri_helper'
require 'net/http'

# TODO: Not used yet, don't load since it'll only be a performance hit
#  require 'net/https'
#  require 'net/ftp'

module FeedTools
  # Methods for pulling remote data
  module RetrievalHelper
    # Stolen from the Universal Feed Parser
    ACCEPT_HEADER = "application/atom+xml,application/rdf+xml," +
      "application/rss+xml,application/x-netcdf,application/xml;" +
      "q=0.9,text/xml;q=0.2,*/*;q=0.1"
    
    # Makes an HTTP request and returns the HTTP response.  Optionally
    # takes a block that determines whether or not to follow a redirect.
    # The block will be passed the HTTP redirect response as an argument.
    def self.http_request(http_operation, url, options={}, &block)
      response = nil
      
      options = {
        :feed_object => nil,
        :form_data => nil,
        :request_headers => {},
        :follow_redirects => true,
        :redirect_limit => 10,
        :response_chain => []
      }.merge(options)
      
      if options[:redirect_limit] == 0
        raise FeedAccessError, 'Redirect too deep'
      end
      
      if options[:response_chain].blank? ||
          !options[:response_chain].kind_of?(Array)
        options[:response_chain] = []
      end
      
      if !options[:request_headers].kind_of?(Hash)
        options[:request_headers] = {}
      end
      if !options[:form_data].kind_of?(Hash)
        options[:form_data] = nil
      end

      if options[:request_headers].blank? && options[:feed_object] != nil
        options[:request_headers] = {}
        unless options[:feed_object].http_headers.nil?
          unless options[:feed_object].http_headers['etag'].nil?
            options[:request_headers]["If-None-Match"] =
              options[:feed_object].http_headers['etag']
          end
          unless options[:feed_object].http_headers['last-modified'].nil?
            options[:request_headers]["If-Modified-Since"] =
              options[:feed_object].http_headers['last-modified']
          end
        end
        unless options[:feed_object].configurations[:user_agent].nil?
          options[:request_headers]["User-Agent"] =
            options[:feed_object].configurations[:user_agent]
        end
      end
      if options[:request_headers]["Accept"].nil?
        options[:request_headers]["Accept"] =
          FeedTools::RetrievalHelper::ACCEPT_HEADER
      end
      if options[:request_headers]["User-Agent"].nil?
        options[:request_headers]["User-Agent"] =
          FeedTools.configurations[:user_agent]
      end
      
      uri = nil
      begin
        uri = URI.parse(url)
      rescue URI::InvalidURIError
        # Uh, maybe try to fix it?
        uri = URI.parse(FeedTools::UriHelper.normalize_url(url))
      end
      
      begin
        proxy_address = nil
        proxy_port = nil
        proxy_user = nil
        proxy_password = nil
        
        auth_user = nil
        auth_password = nil
        auth_scheme = nil
        
        if options[:feed_object] != nil
          proxy_address =
            options[:feed_object].configurations[:proxy_address] || nil
          proxy_port =
            options[:feed_object].configurations[:proxy_port].to_i || nil
          proxy_user =
            options[:feed_object].configurations[:proxy_user] || nil
          proxy_password =
            options[:feed_object].configurations[:proxy_password] || nil

          auth_user =
            options[:feed_object].configurations[:auth_user] || nil
          auth_password =
            options[:feed_object].configurations[:auth_password] || nil
          auth_scheme =
            options[:feed_object].configurations[:auth_scheme] || nil
        end        
        
        if (auth_user &&
            (auth_scheme == nil || auth_scheme.to_s.to_sym == :basic))
          options[:request_headers]["Authorization"] =
            "Basic " + [
              "#{auth_user}:#{auth_password}"
            ].pack('m').delete("\r\n")
        end
        
        # No need to check for nil
        http = Net::HTTP::Proxy(
          proxy_address, proxy_port, proxy_user, proxy_password).new(
            uri.host, (uri.port or 80))

        if options[:feed_object] != nil &&
            options[:feed_object].configurations[:http_timeout] != nil
          http.open_timeout = 
            options[:feed_object].configurations[:http_timeout].to_f
        elsif FeedTools.configurations[:http_timeout] != nil
          http.open_timeout = FeedTools.configurations[:http_timeout].to_f
        end
        if http.open_timeout != nil && http.open_timeout == 0
          http.open_timeout = nil
        end
        
        path = uri.path 
        path += ('?' + uri.query) if uri.query
        
        request_params = [path, options[:request_headers]]
        if http_operation == :post
          options[:form_data] = {} if options[:form_data].blank?
          request_params << options[:form_data]
        end
        Thread.pass
        response = http.send(http_operation, *request_params)
        Thread.pass
        
        case response
        when Net::HTTPSuccess
          if options[:feed_object] != nil
            # We've reached the final destination, process all previous
            # redirections, and see if we need to update the url.
            for redirected_response in options[:response_chain]
              if redirected_response.last.code.to_i == 301
                # Reset the cache object or we may get duplicate entries

                # TODO: verify this line is necessary!
#=============================================================================
                options[:feed_object].cache_object = nil
                
                options[:feed_object].href =
                  redirected_response.last['location']
              else
                # Jump out as soon as we hit anything that isn't a
                # permanently moved redirection.
                break
              end
            end
          end
        when Net::HTTPNotModified
          # Do nothing, we just don't want it processed as a redirection
        when Net::HTTPRedirection
          if response['location'].nil?
            raise FeedAccessError,
              "No location to redirect to supplied for " + response.code
          end
          options[:response_chain] << [url, response]

          redirected_location = response['location']
          redirected_location = FeedTools::UriHelper.resolve_relative_uri(
            redirected_location, [uri.to_s])
          
          if options[:response_chain].assoc(redirected_location) != nil
            raise FeedAccessError,
              "Redirection loop detected: #{redirected_location}"
          end
          
          # Let the block handle redirects
          follow_redirect = true
          if block != nil
            follow_redirect = block.call(redirected_location, response)
          end
          
          if follow_redirect
            response = FeedTools::RetrievalHelper.http_request(
              http_operation,
              redirected_location, 
              options.merge(
                {:redirect_limit => (options[:redirect_limit] - 1)}),
              &block)
          end
        end
      rescue SocketError
        raise FeedAccessError, 'Socket error prevented feed retrieval'
      rescue Timeout::Error, Errno::ETIMEDOUT
        raise FeedAccessError, 'Timeout while attempting to retrieve feed'
      rescue Errno::ENETUNREACH
        raise FeedAccessError, 'Network was unreachable'
      rescue Errno::ECONNRESET
        raise FeedAccessError, 'Connection was reset by peer'
      end
      
      if response != nil
        class << response
          def response_chain
            return @response_chain
          end
        end
        response.instance_variable_set("@response_chain",
          options[:response_chain])
      end
      
      return response
    end
    
    # Makes an HTTP GET request and returns the HTTP response.  Optionally
    # takes a block that determines whether or not to follow a redirect.
    # The block will be passed the HTTP redirect response as an argument.
    def self.http_get(url, options={}, &block)
      return FeedTools::RetrievalHelper.http_request(
        :get, url, options, &block)
    end

    # Makes an HTTP POST request and returns the HTTP response.  Optionally
    # takes a block that determines whether or not to follow a redirect.
    # The block will be passed the HTTP redirect response as an argument.
    def self.http_post(url, options={}, &block)
      return FeedTools::RetrievalHelper.http_request(
        :post, url, options, &block)
    end
    
    # Makes an HTTP HEAD request and returns the HTTP response.  Optionally
    # takes a block that determines whether or not to follow a redirect.
    # The block will be passed the HTTP redirect response as an argument.
    def http_head(url, options={}, &block)
      return FeedTools::RetrievalHelper.http_request(
        :head, url, options, &block)
    end
  end
end
