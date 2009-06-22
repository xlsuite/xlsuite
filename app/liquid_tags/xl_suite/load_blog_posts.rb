#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  class LoadBlogPosts < Liquid::Tag
    PageNumSyntax = /page_num:\s*(#{Liquid::QuotedFragment})/
    PerPageSyntax = /per_page:\s*(#{Liquid::QuotedFragment})/
    SearchSyntax = /search:\s*(#{Liquid::QuotedFragment})/
    TaggedAllSyntax = /tagged_all:\s*(#{Liquid::QuotedFragment})/
    TaggedAnySyntax = /tagged_any:\s*(#{Liquid::QuotedFragment})/
    OrderSyntax = /order:\s*(#{Liquid::QuotedFragment})/
    RandomizeSyntax = /randomize:\s*(#{Liquid::QuotedFragment})/
    IdsSyntax = /ids:\s*(#{Liquid::QuotedFragment})/
    FromBlogsSyntax = /from_blogs:\s*(#{Liquid::QuotedFragment})/
    AllSyntax = /all_blog_posts\s*/
    MonthSyntax = /month:\s*(#{Liquid::QuotedFragment})/
    YearSyntax = /year:\s*(#{Liquid::QuotedFragment})/
    LabelSyntax = /label:\s*(#{Liquid::QuotedFragment})/
    ExcludeSyntax = /exclude:\s*(#{Liquid::QuotedFragment})/

    InSyntax = /in:\s*([\w_]+)/
    PagesCountSyntax = /pages_count:\s*([\w_]+)/
    TotalCountSyntax = /total_count:\s*([\w_]+)/


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
      @options[:from_blogs] = $1 if markup =~ FromBlogsSyntax
      @options[:all_blog_posts] = true if markup =~ AllSyntax
      @options[:randomize] = $1 if markup =~ RandomizeSyntax
      @options[:month] = $1 if markup =~ MonthSyntax
      @options[:year] = $1 if markup =~ YearSyntax
      @options[:label] = $1 if markup =~ LabelSyntax
      @options[:exclude] = $1 if markup =~ ExcludeSyntax
      

      @options[:in] = $1 if markup =~ InSyntax
      @options[:pages_count] = $1 if markup =~ PagesCountSyntax
      @options[:total_count] = $1 if markup =~ TotalCountSyntax

      raise SyntaxError, "Missing in: parameter in #{markup.inspect}" unless @options[:in]

      specifications = [@options[:from_blogs], @options[:label], @options[:search], @options[:tagged_any], @options[:tagged_all], @options[:all_blog_posts], @options[:ids]].flatten.compact
      raise SyntaxError, "One of all_blog_posts, label:, search:, tagged_all:, tagged_any:, from_blogs:, or ids: must be specified in #{markup.inspect}" if specifications.size < 1
    end

    def render(context)
      returning "" do
        options = Hash.new
        context_options = Hash.new

        [:page_num, :per_page, :search, :tagged_any, :tagged_all, :order, :randomize, :ids, :from_blogs, :month, :year, :label, :exclude].each do |option_sym|
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
          o = []
          context_options[:order].split(",").map(&:strip).each do |e|
            e.gsub!(/^created_at/i, "id")
            o << e if e =~ /^(id|published_at|updated_at|title|author_name|average_rating)/i
          end
          orders += o
        else
          orders << "published_at DESC"
        end
        
        options.merge!(:order => orders.join(",")) unless orders.empty?

        conditions = []
        conditions_hash = {}
        conditions << "blog_posts.account_id=#{current_account.id}"
        conditions << "blog_posts.published_at < :time_now"
        conditions_hash.merge!(:time_now => Time.now.utc)

        blog_post_ids = []
        if @options[:ids]
          ids = context_options[:ids].split(",").map(&:strip).reject(&:blank?)
          ids = ids.map(&:to_i)
          blog_post_ids << ids
        end

        from_blog_ids = []
        if @options[:from_blogs]
          ids = [context_options[:from_blogs]].flatten.map(&:id)
          ids = ids.map(&:to_i)
          from_blog_ids += ids
        end

        if @options[:exclude]
          ids = [context_options[:exclude]].flatten.map(&:id)
          ids = ids.map(&:to_i)
          conditions << "blog_posts.id NOT IN (#{ids.join(',')})" unless ids.empty?
        end

        if @options[:label]
          blog = current_account.blogs.find(:first, :conditions => ["label=?", context_options[:label]])
          if blog
            conditions << "blog_posts.blog_id = #{blog.id}"
          end
        end

        if @options[:month]
          month = context_options[:month].to_i
          year = nil
          if @options[:year]
            year = context_options[:year].to_i
          end
          year ||= Time.now.utc.year
          from_time = Time.utc(year, month)
          to_time = Time.utc(year, month+1)
          conditions << "(blog_posts.published_at >= :from_time AND blog_posts.published_at < :to_time)"
          
          conditions_hash.merge!(:from_time => from_time, :to_time => to_time)
        end
        
        group_ids = context.current_user? ? context.current_user.groups.find(:all, :select => "groups.id").map(&:id) : []
        blog_ids = current_account.blogs.find(:all, :select => "blogs.id",
          :joins => [%Q`LEFT JOIN authorizations ON authorizations.object_type="Blog" AND authorizations.object_id=blogs.id`, 
              %Q`LEFT JOIN groups ON groups.id=authorizations.group_id`].join(" "), 
          :conditions => "groups.id IS NULL OR groups.id IN (#{group_ids.join(",").blank? ? 0 : group_ids.join(",")})").map(&:id)
        blog_ids = from_blog_ids & blog_ids unless (!@options[:from_blogs] && from_blog_ids.empty?)
        
        conditions << "blog_posts.blog_id IN (#{blog_ids.join(",")})" unless blog_ids.empty?

        if blog_ids.empty?
          context.scopes.last[@options[:pages_count]] = context[@options[:total_count]] = 0
          context.scopes.last[@options[:in]] = nil
          return
        end
        
        private_blog_ids = current_account.blogs.all(:select => "id", :conditions => {:private => true}).map(&:id)
        if context.current_user?
          owned_blog_ids = context.current_user.blogs.map(&:id)
          expiring_blog_ids = context.current_user.expiring_blogs.map(&:id)
          granted_blog_ids = context.current_user.granted_blogs.map(&:id)
          private_blog_ids = private_blog_ids - (owned_blog_ids + expiring_blog_ids + granted_blog_ids)
        end
        conditions << "blog_posts.blog_id NOT IN (#{private_blog_ids.join(',')})" unless private_blog_ids.blank?
        
        if context[@options[:tagged_any]] =~ /\|\|/
          context_options[:tagged_any].split('||').map(&:strip).each do |tagged_all|
            blog_post_ids = blog_post_ids + current_account.blog_posts.find_tagged_with(:all => Tag.parse(tagged_all)).map(&:id).map(&:to_i)
          end
          @options[:tagged_any] = nil
          @options[:ids] = true
        end
        
        conditions << "blog_posts.id IN (#{blog_post_ids.join(',')})" unless blog_post_ids.empty?
        
        conditions = conditions.join(" AND ")

        options.merge!(:conditions => [conditions, conditions_hash])

        blog_posts_count = 0
        blog_posts = case
                   when @options[:search]
                     q = context_options[:search]
                     BlogPost.search(q, options)
                   when @options[:tagged_all]
                     BlogPost.find_tagged_with(options.merge(:all => Tag.parse(context_options[:tagged_all])))
                   when @options[:tagged_any]
                     BlogPost.find_tagged_with(options.merge(:any => Tag.parse(context_options[:tagged_any])))
                   when @options[:all_blog_posts] || @options[:ids] || @options[:label] || @options[:from_blogs]
                     BlogPost.find(:all, options)
                   else
                     raise SyntaxError, "None of search, tagged_any, tagged_all, all_blog_posts, ids, or from_blogs  available"
                   end

        options.delete(:limit)
        options.delete(:offset)

        if @options[:randomize]
          context_options[:randomize] = context_options[:randomize].to_i
          context_options[:randomize] = 1 if context_options[:randomize] < 1
          blog_posts = blog_posts.sort_by {|_| rand}[0, context_options[:randomize]]
        end

        if @options[:pages_count] || @options[:total_count]
          blog_posts_count = case
                     when @options[:search]
                       q = context_options[:search]
                       BlogPost.count_results(q, {:conditions => options.delete(:conditions)})
                     when @options[:tagged_all]
                       BlogPost.count_tagged_with(options.merge(:all => Tag.parse(context_options[:tagged_all])))
                     when @options[:tagged_any]
                       BlogPost.count_tagged_with(options.merge(:any => Tag.parse(context_options[:tagged_any])))
                     when @options[:all_blog_posts] || @options[:ids] || @options[:from_blogs]
                       BlogPost.count(options)
                     else
                       raise SyntaxError, "None of search, tagged_any, tagged_all, all_blog_posts, ids, or from_blogs available"
                     end
          context.scopes.last[@options[:pages_count]] = (blog_posts_count / limit).to_i + (blog_posts_count % limit > 0 ? 1 : 0)
          context.scopes.last[@options[:total_count]] = blog_posts_count
        end

        context.scopes.last[@options[:in]] = blog_posts
      end
    end
  end
end
