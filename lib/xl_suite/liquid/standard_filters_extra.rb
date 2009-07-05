#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  module Liquid
    module StandardFiltersExtra
      def url_escape(input)
        CGI.escape(input).gsub(/%2F/, "%252F") rescue input
      end

      def param_escape(input)
        CGI.escape(input) rescue input
      end

      def month(input)
        return nil unless input.respond_to?(:month)
        input.month
      end

      def day(input)
        return nil unless input.respond_to?(:day)
        input.day
      end

      def year(input)
        return nil unless input.respond_to?(:year)
        input.year
      end

      def xmlschema(input)
        return nil unless input.respond_to?(:xmlschema)
        input.xmlschema
      end
      
      def strip(input)
        return nil unless input.respond_to?(:strip)
        input.strip
      end
      
      def humanize(input)
        input.humanize
      end
      
      def titleize(input)
        input.titleize
      end
      
      def include_any(input, input2, case_insensitive = false)
        input = input.split(",").map(&:strip) if input.is_a?(String)
        input2 = input2.split(",").map(&:strip) if input2.is_a?(String)
        if case_insensitive
          input = input.map(&:downcase) rescue input
          input2 = input2.map(&:downcase) rescue input2
        end
        input.any?{|i|input2.include?(i)}
      end
      
      def append_affiliate_username(input, username)
        input.append_affiliate_username(username)
      end
      alias_method :append_affiliate_id, :append_affiliate_username
    end
  end
end
