#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  class LoadBlogs < Liquid::Tag
    PageNumSyntax = /page_num:\s*(#{Liquid::QuotedFragment})/
    PerPageSyntax = /per_page:\s*(#{Liquid::QuotedFragment})/
    SearchSyntax = /search:\s*(#{Liquid::QuotedFragment})/
    TaggedAllSyntax = /tagged_all:\s*(#{Liquid::QuotedFragment})/
    TaggedAnySyntax = /tagged_any:\s*(#{Liquid::QuotedFragment})/
    OrderSyntax = /order:\s*(#{Liquid::QuotedFragment})/
    RandomizeSyntax = /randomize:\s*(#{Liquid::QuotedFragment})/
    IdsSyntax = /ids:\s*(#{Liquid::QuotedFragment})/    
    InSyntax = /in:\s*([\w_]+)/
    AllSyntax = /all_blogs\s*/
    PagesCountSyntax = /pages_count:\s*([\w_]+)/
    TotalCountSyntax = /total_count:\s*([\w_]+)/
    ExcludeSyntax = /exclude:\s*(#{Liquid::QuotedFragment})/
    PrivateSyntax = /private:\s*(#{Liquid::QuotedFragment})/

    def initialize(tag_name, markup, tokens)
      super

      @options = Hash.new
      @options[:page_num] = $1 if markup =~ PageNumSyntax
      @options[:per_page] = $1 if markup =~ PerPageSyntax
      @options[:search] = $1 if markup =~ SearchSyntax
      @options[:tagged_all] = $1 if markup =~ TaggedAllSyntax
      @options[:tagged_any] = $1 if markup =~ TaggedAnySyntax
      @options[:order] = $1 if markup =~ OrderSyntax
      @options[:ids] = $1 if markup =~ IdsSyntax
      @options[:all_blogs] = true if markup =~ AllSyntax
      @options[:randomize] = $1 if markup =~ RandomizeSyntax
      @options[:exclude] = $1 if markup =~ ExcludeSyntax
      @options[:private] = $1 if markup =~ PrivateSyntax

      @options[:in] = $1 if markup =~ InSyntax
      @options[:pages_count] = $1 if markup =~ PagesCountSyntax
      @options[:total_count] = $1 if markup =~ TotalCountSyntax

      raise SyntaxError, "Missing in: parameter in #{markup.inspect}" unless @options[:in]

      specifications = [@options[:search], @options[:tagged_any], @options[:tagged_all], @options[:all_blogs], @options[:ids]].flatten.compact
      raise SyntaxError, "One of all_blogs, search:, tagged_all:, tagged_any:, or ids: must be specified in #{markup.inspect}" if specifications.size < 1
    end

    def render(context)
      returning "" do
        options = Hash.new
        context_options = Hash.new
        
        [:page_num, :per_page, :search, :tagged_any, :tagged_all, :order, :randomize, :ids, :exclude, :private].each do |option_sym|
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
        conditions << "blogs.account_id=#{current_account.id}"

        if @options[:ids]
          ids = context_options[:ids].split(",").map(&:strip).reject(&:blank?)
          ids = ids.map(&:to_i)
          conditions << "blogs.id IN (#{ids.join(',')})" unless ids.empty?
        end      

        if @options[:exclude]
          ids = [context_options[:exclude]].flatten.map(&:id)
          ids = ids.map(&:to_i)
          conditions << "blogs.id NOT IN (#{ids.join(',')})" unless ids.empty?
        end    

        group_ids = context.current_user? ? context.current_user.groups.find(:all, :select => "groups.id").map(&:id) : []
        blog_ids = current_account.blogs.find(:all, :select => "blogs.id",
          :joins => [%Q`LEFT JOIN authorizations ON authorizations.object_type="Blog" AND authorizations.object_id=blogs.id`, 
              %Q`LEFT JOIN groups ON groups.id=authorizations.group_id`].join(" "), 
          :conditions => "groups.id IS NULL OR groups.id IN (#{group_ids.join(",").blank? ? 0 : group_ids.join(",")})").map(&:id)
        
        if blog_ids.blank?
          context[@options[:pages_count]] = context[@options[:total_count]] = 0
          context[@options[:in]] = nil
          return
        end
        
        expiring_blogs_ids = context.current_user? ? ExpiringPartyItem.all(:conditions => {:party_id => context.current_user.id, :item_type => "Blog"}, :select => 'item_id').map(&:item_id) : []
        granted_blogs_ids = context.current_user? ? context.current_user.granted_blogs.map(&:id) : []
        accessible_blogs_ids = expiring_blogs_ids + granted_blogs_ids
        
        if @options[:private]
          ids = []
          if context.current_user? 
            party = context.current_user
            if expiring_blogs_ids.empty?
              conditions << "blogs.id IN (0)"
            else
              conditions << "blogs.id in (#{expiring_blogs_ids.join(',')})"
            end
          else
            conditions << "blogs.id IN (0)"
          end
        end
        
        private_blog_ids = current_account.blogs.all(:select => "id", :conditions => {:private => true}).map(&:id)
        if context.current_user?
          owned_blog_ids = context.current_user.blogs.map(&:id)
          private_blog_ids = private_blog_ids - (owned_blog_ids + accessible_blogs_ids)
        end
        conditions << "blogs.id NOT IN (#{private_blog_ids.join(',')})" unless private_blog_ids.blank?
        
        conditions << "blogs.id IN (#{blog_ids.join(",")})"

        conditions = [conditions.join(" AND ")]
        options.merge!(:conditions => conditions.to_s)
        
        blogs_count = 0
        
        blogs = case
                   when @options[:search]
                     q = context_options[:search]
                     Blog.search(q, options)
                   when @options[:tagged_all]
                     Blog.find_tagged_with(options.merge(:all => Tag.parse(context_options[:tagged_all])))
                   when @options[:tagged_any]
                     Blog.find_tagged_with(options.merge(:any => Tag.parse(context_options[:tagged_any])))
                   when @options[:all_blogs] || @options[:ids]
                     Blog.find(:all, options)
                   else
                     raise SyntaxError, "None of search, tagged_any, tagged_all or all_blogs available"
                   end
                   
        options.delete(:limit)
        options.delete(:offset)
        
        if @options[:randomize]
          context_options[:randomize] = context_options[:randomize].to_i
          context_options[:randomize] = 1 if context_options[:randomize] < 1
          blogs = blogs.sort_by {|_| rand}[0, context_options[:randomize]]
        end
        
        if @options[:pages_count] || @options[:total_count]
          blogs_count = case
                     when @options[:search]
                       q = context_options[:search]
                       Blog.count_results(q, {:conditions => options.delete(:conditions)})
                     when @options[:tagged_all]
                       Blog.count_tagged_with(options.merge(:all => Tag.parse(context_options[:tagged_all])))
                     when @options[:tagged_any]
                       Blog.count_tagged_with(options.merge(:any => Tag.parse(context_options[:tagged_any])))
                     when @options[:all_blogs] || @options[:ids]
                       Blog.count(options)          
                     else
                       raise SyntaxError, "None of search, tagged_any, tagged_all or all_blogs available"
                     end
          context.scopes.last[@options[:pages_count]] = (blogs_count / limit).to_i + (blogs_count % limit > 0 ? 1 : 0)
          context.scopes.last[@options[:total_count]] = blogs_count
        end
        
        context.scopes.last[@options[:in]] = blogs
      end
    end
  end
end
