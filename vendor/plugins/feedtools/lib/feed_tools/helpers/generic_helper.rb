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

module FeedTools
  # Generic methods needed in numerous places throughout FeedTools
  module GenericHelper
    # Raises an exception if an invalid option has been specified to prevent
    # misspellings from slipping through 
    def self.validate_options(valid_option_keys, supplied_option_keys)
      unknown_option_keys = supplied_option_keys - valid_option_keys
      unless unknown_option_keys.empty?
        raise "Unknown options: #{unknown_option_keys}"
      end
    end
    
    # Nifty little method that takes a block and returns nil if recursion
    # occurs or the block's result value if it doesn't.
    def self.recursion_trap(lock_object, &block)
      if @lock_ids.nil?
        @lock_ids = []
      end
      if !@lock_ids.include?(lock_object.object_id)
        @lock_ids << lock_object.object_id
      else
        return nil
      end
      begin
        result = block.call
      rescue SystemStackError
        result = nil
      end
      @lock_ids.delete(lock_object.object_id)
      return result
    end
  end
end
