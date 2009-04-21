#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  module SphinxSearch
    def self.included(base)
      base.send :extend, XlSuite::SphinxSearch::ClassMethods
    end
    
    module ClassMethods
      def xl_sphinx_search(query, options)
        options = options.dup
        params_start = options.delete(:start)
        params_limit = options.delete(:limit)
        start = (params_start.blank? ? 0 : params_start.to_i)
        limit = (params_limit.blank? ? 50 : params_limit.to_i)
        if options[:offset]
          start = options.delete(:offset).to_i
        end
        if query.blank?
          options.delete(:with)
          self.find(:all, {:offset => start, :limit => limit}.reverse_merge(options))
        else
          page = (start / limit + 1).to_i
          query = self.to_sphinx_query(query)
          self.sphinx_search(query, {:per_page => limit, :page => page}.reverse_merge(options))
        end
      end
      
      def xl_sphinx_search_count(query, options)
        options.delete(:limit)
        options.delete(:offset)
        options.delete(:start)
        options.delete(:order)
        if query.blank?
          options.delete(:with)
          self.count(options)
        else
          query = self.to_sphinx_query(query)
          self.search_count(query, options)
        end
      end
      
      def to_sphinx_query(text)
        text = text.split(/\s+/)
        out = []
        text.each do |word|
          out << "*#{word}*"
        end
        out.join(" ")
      end
    end
  end
end
