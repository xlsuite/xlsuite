#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  class LoadLinks < Liquid::Tag
    PageSyntax = /page:\s*(#{Liquid::QuotedFragment})/
    PerPageSyntax = /per_page:\s*(#{Liquid::QuotedFragment})/
    SearchSyntax = /search:\s*(#{Liquid::QuotedFragment})/
    TaggedAllSyntax = /tagged_all:\s*(#{Liquid::QuotedFragment})/
    TaggedAnySyntax = /tagged_any:\s*(#{Liquid::QuotedFragment})/
    ApprovedSyntax = /approved:\s*(#{Liquid::QuotedFragment})/
    RandomizeSyntax = /randomize:\s*(#{Liquid::QuotedFragment})/
    OrderSyntax = /order:\s*(#{Liquid::QuotedFragment})/
    PagesCountSyntax = /pages_count:\s*([\w_]+)/
    TotalCountSyntax = /total_count:\s*([\w_]+)/
    AllSyntax = /all_links\s*/
    IdsSyntax = /ids:\s*(#{Liquid::QuotedFragment})/    
    InSyntax = /in:\s*(\w+)/

    def initialize(tag_name, markup, tokens)
      super

      @options = Hash.new
      @options[:page] = $1 if markup =~ PageSyntax
      @options[:per_page] = $1 if markup =~ PerPageSyntax
      @options[:search] = $1 if markup =~ SearchSyntax
      @options[:tagged_all] = $1 if markup =~ TaggedAllSyntax
      @options[:tagged_any] = $1 if markup =~ TaggedAnySyntax
      @options[:approved] = $1 if markup =~ ApprovedSyntax
      @options[:randomize] = $1 if markup =~ RandomizeSyntax
      @options[:order] = $1 if markup =~ OrderSyntax
      @options[:pages_count] = $1 if markup =~ PagesCountSyntax
      @options[:total_count] = $1 if markup =~ TotalCountSyntax
      @options[:all_links] = true if markup =~ AllSyntax
      @options[:ids] = $1 if markup =~ IdsSyntax
      @options[:in] = $1 if markup =~ InSyntax

      raise SyntaxError, "Missing in: parameter in #{markup.inspect}" unless @options[:in]

      specifications = [@options[:search], @options[:ids], @options[:all_links], @options[:tagged_any], @options[:tagged_all]].flatten.compact
      raise SyntaxError, "One of all_links, ids:, search:, tagged_all: or tagged_any: must be specified in #{markup.inspect}" if specifications.size != 1
    end

    def render(context)
      returning "" do
        options = Hash.new

        page = Integer(context[@options[:page]] || 1) - 1
        limit = Integer(context[@options[:per_page]] || 100)
        offset = page * limit

        current_account = context.current_account
        
        options = {}
        options = {:limit => limit, :offset => offset} unless @options[:randomize]
        
        if @options[:order]    
          options.merge!(:order => context[@options[:order]]) 
        end
        
        conditions = []

        case @options[:approved]
          when /false/i
            conditions << "approved = 0"
          when /any/i
            #do nothing
          else
            conditions << "approved = 1"
        end
        
        time_now = Time.now().strftime("%Y-%m-%d %H:%M:%S")
        conditions << "active_at < '#{time_now}' AND ( inactive_at IS NULL OR inactive_at > '#{time_now}' )"
        
        if @options[:ids]
          ids = context[@options[:ids]].split(",").map(&:strip).reject(&:blank?)
          ids = ids.map(&:to_i)
          conditions << "links.id IN (#{ids.join(',')})" unless ids.empty?
        end 
        
        conditions = [conditions.join(" AND ")]
        options.merge!(:conditions => conditions.to_s)
        
        links = case
                   when @options[:search]
                     q = context[@options[:search]]
                     current_account.links.search(q, options)
                   when @options[:tagged_all]
                     current_account.links.find_tagged_with(options.merge(:all => context[@options[:tagged_all]]))
                   when @options[:tagged_any]
                     current_account.links.find_tagged_with(options.merge(:any => context[@options[:tagged_any]]))
                   when @options[:all_links] || @options[:ids]
                     current_account.links.find(:all, options)
                   else
                     raise SyntaxError, "None of search, tagged any or all available"
                 end
        
        options.delete(:limit)
        options.delete(:offset)
        
        if @options[:randomize]
          randomize_option = context[@options[:randomize]].to_i
          randomize_option = 1 if randomize_option < 1
          links = links.sort_by {|_| rand}[0, randomize_option]
        end
        
        if @options[:pages_count] || @options[:total_count]
          links_count = case
                   when @options[:search]
                     q = context[@options[:search]]
                     current_account.links.count(q, options)
                   when @options[:tagged_all]
                     current_account.links.count_tagged_with(options.merge(:all => context[@options[:tagged_all]]))
                   when @options[:tagged_any]
                     current_account.links.count_tagged_with(options.merge(:any => context[@options[:tagged_any]]))
                   when @options[:all_links] || @options[:ids]
                     current_account.links.count(options)
                   else
                     raise SyntaxError, "None of search, tagged any or all available"
                 end
          context[@options[:pages_count]] = (links_count / limit).to_i + (links_count % limit > 0 ? 1 : 0)
          context[@options[:total_count]] = links_count
        end
        
        context[@options[:in]] = links
      end
    end
  end
end
