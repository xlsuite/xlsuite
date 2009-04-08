#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  class LoadComments < Liquid::Tag
    PageNumSyntax = /page_num:\s*(#{Liquid::QuotedFragment})/
    PerPageSyntax = /per_page:\s*(#{Liquid::QuotedFragment})/
    SearchSyntax = /search:\s*(#{Liquid::QuotedFragment})/
    OrderSyntax = /order:\s*(#{Liquid::QuotedFragment})/
    RandomizeSyntax = /randomize:\s*(#{Liquid::QuotedFragment})/
    IdsSyntax = /ids:\s*(#{Liquid::QuotedFragment})/    
    InSyntax = /in:\s*([\w_]+)/
    AllSyntax = /all_comments\s*/
    PagesCountSyntax = /pages_count:\s*([\w_]+)/
    TotalCountSyntax = /total_count:\s*([\w_]+)/
    ExcludeSyntax = /exclude:\s*(#{Liquid::QuotedFragment})/
    FromSyntax = /from:\s*(#{Liquid::QuotedFragment})/

    def initialize(tag_name, markup, tokens)
      super

      @options = Hash.new
      @options[:page_num] = $1 if markup =~ PageNumSyntax
      @options[:per_page] = $1 if markup =~ PerPageSyntax
      @options[:search] = $1 if markup =~ SearchSyntax
      @options[:order] = $1 if markup =~ OrderSyntax
      @options[:ids] = $1 if markup =~ IdsSyntax
      @options[:all_comments] = true if markup =~ AllSyntax
      @options[:randomize] = $1 if markup =~ RandomizeSyntax
      @options[:exclude] = $1 if markup =~ ExcludeSyntax
      @options[:from] = $1 if markup =~ FromSyntax

      @options[:in] = $1 if markup =~ InSyntax
      @options[:pages_count] = $1 if markup =~ PagesCountSyntax
      @options[:total_count] = $1 if markup =~ TotalCountSyntax

      raise SyntaxError, "Missing in: parameter in #{markup.inspect}" unless @options[:in]

      specifications = [@options[:search], @options[:all_comments], @options[:ids], @options[:from]].flatten.compact
      raise SyntaxError, "One of all_comments, search:, from:, or ids: must be specified in #{markup.inspect}" if specifications.size < 1
    end

    def render(context)
      returning "" do
        options = Hash.new
        context_options = Hash.new
        
        [:page_num, :per_page, :search, :order, :randomize, :ids, :exclude, :from].each do |option_sym|
          context_options[option_sym] = context[@options[option_sym]]
          context_options[option_sym] = @options[option_sym] unless context_options[option_sym]
        end
        
        page = (context_options[:page_num].blank? ? 1 : context_options[:page_num].to_i) - 1
        page = 0 if page < 0
        limit = context_options[:per_page].blank? ? 100 : context_options[:per_page].to_i
        offset = page * limit

        current_account = context.current_account
        
        options = {}
        options = {:limit => limit, :offset => offset} unless @options[:randomize]
        
        orders = []
        if @options[:order]
          orders << context_options[:order]
        end
        
        options.merge!(:order => orders.join(",")) unless orders.blank? 

        conditions = []
        conditions << "comments.account_id=#{current_account.id}"

        if @options[:ids]
          ids = context_options[:ids].split(",").map(&:strip).reject(&:blank?)
          ids = ids.map(&:to_i)
          conditions << "comments.id IN (#{ids.join(',')})" unless ids.empty?
        end      

        if @options[:exclude]
          ids = [context_options[:exclude]].flatten.map(&:id)
          ids = ids.map(&:to_i)
          conditions << "comments.id NOT IN (#{ids.join(',')})" unless ids.empty?
        end
        
        from_ids = []
        if @options[:from]
          ids = [context_options[:from]].flatten.map(&:id)
          
          if [context_options[:from]].flatten.first.class.name =~ /BlogPost/i
            ids = ids.map(&:to_i)
            if ids.empty?
              conditions << "comments.commentable_id IN (0)"
            else
              conditions << "comments.commentable_id IN (#{ids.join(",")}) AND comments.commentable_type = 'BlogPost'" 
            end
          end
        end

        conditions << "comments.approved_at IS NOT NULL AND comments.spam = 0"

        conditions = [conditions.join(" AND ")]
        options.merge!(:conditions => conditions.to_s)
        
        comments_count = 0
        
        comments = case
                   when @options[:search]
                     q = context_options[:search]
                     Comment.search(q, options)
                   when @options[:all_comments] || @options[:ids] || @options[:from]
                     Comment.find(:all, options)
                   else
                     raise SyntaxError, "None of search, ids, from, or all_comments available"
                   end
                   
        options.delete(:limit)
        options.delete(:offset)
        
        if @options[:randomize]
          context_options[:randomize] = context_options[:randomize].to_i
          context_options[:randomize] = 1 if context_options[:randomize] < 1
          comments = comments.sort_by {|_| rand}[0, context_options[:randomize]]
        end
        
        if @options[:pages_count] || @options[:total_count]
          comments_count = case
                     when @options[:search]
                       q = context_options[:search]
                       Comment.count_results(q, {:conditions => options.delete(:conditions)})
                     when @options[:all_comments] || @options[:ids] || @options[:from]
                       Comment.count(options)          
                     else
                       raise SyntaxError, "None of search, ids, from, or all_comments available"
                     end
          context[@options[:pages_count]] = (comments_count / limit).to_i + (comments_count % limit > 0 ? 1 : 0)
          context[@options[:total_count]] = comments_count
        end
        
        context[@options[:in]] = comments
      end
    end
  end
end
