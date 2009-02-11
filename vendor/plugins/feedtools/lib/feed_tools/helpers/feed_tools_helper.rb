#--
# Copyright (c) 2005 Robert Aman
#
# Contributors: Jens Kraemer
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
#
#++

require 'feed_tools'
require 'feed_tools/helpers/generic_helper'

# This module provides helper methods for simplifying normal interactions with
# the FeedTools library.
module FeedTools
  module FeedToolsHelper
  
    @@default_local_path = File.expand_path('.')
  
    # Returns the default path to load local files from
    def self.default_local_path
      @@default_local_path
    end
  
    # Sets the default path to load local files from
    def self.default_local_path=(new_default_local_path)
      @@default_local_path = new_default_local_path
    end

  protected
    # Loads a feed within a block for more consistent syntax and control
    # over the FeedTools environment.
    def with_feed(options={})
      FeedTools::GenericHelper.validate_options([ :from_file,
                                                  :from_url,
                                                  :from_data,
                                                  :feed_cache ],
                       options.keys)
      options = { :feed_cache =>
        FeedTools.configurations[:feed_cache] }.merge(options)
      if options[:from_file]
        file_path = File.expand_path(@@default_local_path + '/' +
          options[:from_file])
        if !File.exists?(file_path)
          file_path = File.expand_path(options[:from_file])
        end
        if !File.exists?(file_path)
          raise "No such file - #{file_path}"
        end
        feed = FeedTools::Feed.open("file://#{file_path}")
      elsif options[:from_url]
        feed = FeedTools::Feed.open(options[:from_url])
      elsif options[:from_data]
        feed = FeedTools::Feed.new
        feed.feed_data = options[:from_data]
      else
        raise "No data source specified"
      end
      @@save_cache = FeedTools.configurations[:feed_cache].to_s
      FeedTools.configurations[:feed_cache] = options[:feed_cache].to_s
      yield feed
      FeedTools.configurations[:feed_cache] = @@save_cache
      feed = nil
    end
  end
end