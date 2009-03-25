#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  class LoadTags < Liquid::Tag
    PageNumSyntax = /page_num:\s*(#{Liquid::QuotedFragment})/
    PerPageSyntax = /per_page:\s*(#{Liquid::QuotedFragment})/
    OrderSyntax = /order:\s*(#{Liquid::QuotedFragment})/
    RandomizeSyntax = /randomize:\s*(#{Liquid::QuotedFragment})/
    FromBlogPostsSyntax = /from_blog_posts:\s*(#{Liquid::QuotedFragment})/

    InSyntax = /in:\s*([\w_]+)/
    PagesCountSyntax = /pages_count:\s*([\w_]+)/
    TotalCountSyntax = /total_count:\s*([\w_]+)/


    def initialize(tag_name, markup, tokens)
      super

      @options = Hash.new
      @options[:page_num] = $1 if markup =~ PageNumSyntax
      @options[:per_page] = $1 if markup =~ PerPageSyntax
      @options[:order] = $1 if markup =~ OrderSyntax
      @options[:from_blog_posts] = $1 if markup =~ FromBlogPostsSyntax
      @options[:randomize] = $1 if markup =~ RandomizeSyntax

      @options[:in] = $1 if markup =~ InSyntax
      @options[:pages_count] = $1 if markup =~ PagesCountSyntax
      @options[:total_count] = $1 if markup =~ TotalCountSyntax

      raise SyntaxError, "Missing in: parameter in #{markup.inspect}" unless @options[:in]

      specifications = [@options[:from_blog_posts]].flatten.compact
      raise SyntaxError, "One of from_blog_posts: must be specified in #{markup.inspect}" if specifications.size < 1
    end

    def render(context)
      returning "" do
        options = Hash.new
        context_options = Hash.new

        [:page_num, :per_page, :order, :randomize, :from_blog_posts].each do |option_sym|
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
        else
          orders << "name ASC"
        end

        options.merge!(:order => orders.join(",")) unless orders.blank?

        conditions = []
        conditions_hash = {}
        conditions << "tags.account_id=#{current_account.id}"

        from_blog_post_ids = []
        if @options[:from_blog_posts]
          ids = [context_options[:from_blog_posts]].flatten.map(&:id)
          ids = ids.map(&:to_i)
          from_blog_post_ids += ids
        end
        
        tag_ids = current_account.tags.find(:all, :select => "tags.id",
          :joins => [%Q`LEFT JOIN taggings ON taggings.taggable_type ="BlogPost" AND taggings.tag_id=tags.id`, 
              %Q`LEFT JOIN blog_posts ON blog_posts.id=taggings.taggable_id`].join(" "), 
          :conditions => "blog_posts.id IN (#{from_blog_post_ids.join(",").blank? ? 0 : from_blog_post_ids.join(",")})").map(&:id)
        
        if tag_ids.empty?
          context[@options[:pages_count]] = context[@options[:total_count]] = 0
          context[@options[:in]] = nil
          return
        else
          conditions << "tags.id IN (#{tag_ids.join(',')})" 
        end
        
        conditions = conditions.join(" AND ")

        options.merge!(:conditions => [conditions, conditions_hash])

        tags_count = 0
        tags = case
                   when @options[:from_blog_posts]
                     Tag.find(:all, options)
                   else
                     raise SyntaxError, "None of from_blog_posts available"
                   end

        options.delete(:limit)
        options.delete(:offset)

        if @options[:randomize]
          context_options[:randomize] = context_options[:randomize].to_i
          context_options[:randomize] = 1 if context_options[:randomize] < 1
          tags = tags.sort_by {|_| rand}[0, context_options[:randomize]]
        end

        if @options[:pages_count] || @options[:total_count]
          tags_count = case
                     when @options[:from_blog_posts]
                       BlogPost.count(options)
                     else
                       raise SyntaxError, "None of from_blog_posts available"
                     end
          context[@options[:pages_count]] = (tags_count / limit).to_i + (tags_count % limit > 0 ? 1 : 0)
          context[@options[:total_count]] = tags_count
        end

        context[@options[:in]] = tags
      end
    end
  end
end
