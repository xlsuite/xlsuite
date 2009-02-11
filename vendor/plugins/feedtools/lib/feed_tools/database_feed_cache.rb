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

require 'rubygems'
require 'active_record'

#= database_feed_cache.rb
#
# The <tt>DatabaseFeedCache</tt> is the default caching mechanism for
# FeedTools.  This mechanism can be replaced easily by creating another
# class with the required set of methods and setting
# <tt>FeedTools#feed_cache</tt> to the new class.
module FeedTools
  # The default caching mechanism for the FeedTools module
  class DatabaseFeedCache < ActiveRecord::Base
    # Overrides the default table name to use the "feeds" table.
    set_table_name("cached_feeds")
  
    # If ActiveRecord is not already connected, attempts to find a configuration file and use
    # it to open a connection for ActiveRecord.
    # This method is probably unnecessary for anything but testing and debugging purposes.
    # In a Rails environment, the connection will already have been established
    # and this method will simply do nothing.
    #
    # This method should not raise any exceptions because it's designed to be run only when
    # the module is first loaded.  If it fails, the user should get an exception when they
    # try to perform some action that makes use of the caching functionality, and not until.
    def DatabaseFeedCache.initialize_cache
      # Establish a connection if we don't already have one
      begin
        ActiveRecord::Base.default_timezone = :utc
        ActiveRecord::Base.connection
      rescue
      end
      if !ActiveRecord::Base.connected?
        begin
          possible_config_files = [
            "./config/database.yml",
            "./database.yml",
            "../config/database.yml",
            "../database.yml",
            "../../config/database.yml",
            "../../database.yml",
            "../../../config/database.yml",
            "../../../database.yml"
          ]
          database_config_file = nil
          for file in possible_config_files
            if File.exists?(File.expand_path(file))
              database_config_file = file
              @config_path = database_config_file
              break
            end
          end
          database_config_hash = File.open(database_config_file) do |file|
            config_hash = YAML::load(file)
            unless config_hash[FEED_TOOLS_ENV].nil?
              config_hash = config_hash[FEED_TOOLS_ENV]
            end
            config_hash
          end
          ActiveRecord::Base.configurations = database_config_hash
          ActiveRecord::Base.establish_connection(database_config_hash)
          ActiveRecord::Base.connection
        rescue
        end
      end
      return nil
    end
    
    # Returns the path to the database.yml config file that FeedTools loaded.
    def DatabaseFeedCache.config_path
      if !defined?(@config_path) || @config_path.blank?
        @config_path = nil
      end
      return @config_path
    end

    # Returns true if a connection to the database has been established and the
    # required table structure is in place.
    def DatabaseFeedCache.connected?
      begin
        ActiveRecord::Base.connection
        return false if ActiveRecord::Base.configurations.nil?
        return false unless DatabaseFeedCache.table_exists?
      rescue => error
        return false
      end
      return true
    end
    
    # False if there is an error of any kind
    def DatabaseFeedCache.set_up_correctly?
      begin
        ActiveRecord::Base.connection
        if !ActiveRecord::Base.configurations.nil? &&
          !DatabaseFeedCache.table_exists?
          return false
        end
      rescue Exception
        return false
      end
      return true
    end
    
    # True if the appropriate database table already exists
    def DatabaseFeedCache.table_exists?
      begin
        ActiveRecord::Base.connection.select_one("select id, href, title, " +
          "link, feed_data, feed_data_type, http_headers, last_retrieved " +
          "from #{self.table_name()}")
      rescue ActiveRecord::StatementInvalid
        return false
      rescue
        return false
      end
      return true
    end
  end
end