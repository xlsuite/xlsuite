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
    end
  end
end
