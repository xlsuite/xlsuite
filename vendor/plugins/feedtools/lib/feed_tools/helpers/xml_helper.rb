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
require 'feed_tools/helpers/generic_helper'
require 'rexml/document'

module FeedTools
  # Generic xml methods needed in numerous places throughout FeedTools
  module XmlHelper    
    # Selects the first non-blank result.
    def self.select_not_blank(results, &block)
      if results.kind_of? Array
        for result in results
          blank_result = false
          if !block.nil?
            blank_result = block.call(result)
          else
            blank_result = result.to_s.blank?
          end
          unless result.nil? || blank_result
            return result
          end
        end
      else
        blank_result = false
        if !block.nil?
          blank_result = block.call(results)
        else
          blank_result = results.to_s.blank?
        end
        unless results.nil? || blank_result
          return results
        end
      end
      return nil
    end
    
    # Runs through a list of XPath queries on an element or document and
    # returns the first non-blank result.  Subsequent XPath queries will
    # not be evaluated.
    def self.try_xpaths(element, xpath_list,
        options={}, &block)
      FeedTools::GenericHelper.validate_options([ :select_result_value ],
                       options.keys)
      options = { :select_result_value => false }.merge(options)

      result = nil
      if element.nil?
        return nil
      end
      for xpath in xpath_list
        # Namespace aware
        result = REXML::XPath.liberal_first(element, xpath,
          FEED_TOOLS_NAMESPACES)
        if options[:select_result_value] && !result.nil?
          if result.respond_to?(:value)
            result = result.value
          else
            result = result.to_s
          end
        end
        blank_result = false
        if block_given?
          blank_result = yield(result)
        else
          blank_result = result.to_s.blank?
        end
        if !blank_result
          if result.respond_to? :strip
            result.strip!
          end
          return result
        end
        
        # Namespace unaware
        result = REXML::XPath.liberal_first(element, xpath)
        if options[:select_result_value] && !result.nil?
          if result.respond_to?(:value)
            result = result.value
          else
            result = result.to_s
          end
        end
        blank_result = false
        if block_given?
          blank_result = yield(result)
        else
          blank_result = result.to_s.blank?
        end
        if !blank_result
          if result.respond_to? :strip
            result.strip!
          end
          return result
        end
      end
      return nil
    end
    
    # Runs through a list of XPath queries on an element or document and
    # returns all non-empty results.  Subsequent XPath queries will
    # not be evaluated.
    def self.try_xpaths_all(element, xpath_list, options={})
      FeedTools::GenericHelper.validate_options([ :select_result_value ],
                       options.keys)
      options = { :select_result_value => false }.merge(options)

      results = []
      if element.nil?
        return []
      end
      for xpath in xpath_list
        # Namespace aware
        results = REXML::XPath.liberal_match(element, xpath,
          FEED_TOOLS_NAMESPACES)
        if options[:select_result_value] && !results.nil? && !results.empty?
          results =
            results.map { |x| x.respond_to?(:value) ? x.value : x.to_s }
        end
        if results.blank?
          results = REXML::XPath.liberal_match(element, xpath)
        else
          return results
        end
        
        # Namespace unaware
        if options[:select_result_value] && !results.nil? && !results.empty?
          results =
            results.map { |x| x.respond_to?(:value) ? x.value : x.to_s }
        end
        if !results.blank?
          return results
        end
      end
      for xpath in xpath_list
        if xpath =~ /^\w+$/
          results = []
          for child in element.children
            if child.class == REXML::Element
              if child.name.downcase == xpath.downcase
                results << child
              end
            end
          end
          if options[:select_result_value] && !results.nil? && !results.empty?
            results =
              results.map { |x| x.inner_xml }
          end
          if !results.blank?
            return results
          end
        end
      end
      return []
    end
    
    # Runs through a list of XPath queries on an element or document and
    # returns all non-empty results, appending the results from each query
    # onto the end of the results from the previous queries.
    def self.combine_xpaths_all(element, xpath_list, options={})
      FeedTools::GenericHelper.validate_options([ :select_result_value ],
                       options.keys)
      options = { :select_result_value => false }.merge(options)

      all_results = []
      result = []
      if element.nil?
        return []
      end
      for xpath in xpath_list
        # Namespace aware
        results = REXML::XPath.liberal_match(element, xpath,
          FEED_TOOLS_NAMESPACES)
        if options[:select_result_value] && !results.nil? && !results.empty?
          results =
            results.map { |x| x.respond_to?(:value) ? x.value : x.to_s }
        end
        if results.blank?
          results = REXML::XPath.liberal_match(element, xpath)
        else
          all_results.concat(results)
          next
        end

        # Namespace unaware
        if options[:select_result_value] && !results.nil? && !results.empty?
          results =
            results.map { |x| x.respond_to?(:value) ? x.value : x.to_s }
        end
        if !results.blank?
          all_results.concat(results)
          next
        end
      end
      for xpath in xpath_list
        if xpath =~ /^\w+$/
          results = []
          for child in element.children
            if child.class == REXML::Element
              if child.name.downcase == xpath.downcase
                results << child
              end
            end
          end
          if options[:select_result_value] && !results.nil? && !results.empty?
            results =
              results.map { |x| x.inner_xml }
          end
          if !results.blank?
            all_results.concat(results)
            next
          end
        end
      end
      return all_results.uniq
    end
  end
end