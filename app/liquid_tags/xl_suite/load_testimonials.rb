#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  class LoadTestimonials < Liquid::Tag
    PageNumSyntax = /page_num:\s*(#{Liquid::QuotedFragment})/
    PerPageSyntax = /per_page:\s*(#{Liquid::QuotedFragment})/
    SearchSyntax = /search:\s*(#{Liquid::QuotedFragment})/
    TaggedAllSyntax = /tagged_all:\s*(#{Liquid::QuotedFragment})/
    TaggedAnySyntax = /tagged_any:\s*(#{Liquid::QuotedFragment})/
    OrderSyntax = /order:\s*(#{Liquid::QuotedFragment})/
    RandomizeSyntax = /randomize:\s*(#{Liquid::QuotedFragment})/
    IdsSyntax = /ids:\s*(#{Liquid::QuotedFragment})/    
    InSyntax = /in:\s*([\w_]+)/
    AllSyntax = /all_testimonials\s*/
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
      @options[:all_testimonials] = true if markup =~ AllSyntax
      @options[:randomize] = $1 if markup =~ RandomizeSyntax

      @options[:in] = $1 if markup =~ InSyntax
      @options[:pages_count] = $1 if markup =~ PagesCountSyntax
      @options[:total_count] = $1 if markup =~ TotalCountSyntax

      raise SyntaxError, "Missing in: parameter in #{markup.inspect}" unless @options[:in]

      specifications = [@options[:search], @options[:tagged_any], @options[:tagged_all], @options[:all_testimonials], @options[:ids]].flatten.compact
      raise SyntaxError, "One of all_testimonials, search:, tagged_all:, tagged_any:, or ids: must be specified in #{markup.inspect}" if specifications.size < 1
    end

    def render(context)
      returning "" do
        options = Hash.new
        context_options = Hash.new
        
        [:page_num, :per_page, :search, :tagged_any, :tagged_all, :order, :randomize, :ids].each do |option_sym|
          context_options[option_sym] = context[@options[option_sym]]
          context_options[option_sym] = @options[option_sym] unless context_options[option_sym]
        end
        
        page = (context_options[:page_num].blank? ? 1 : context_options[:page_num].to_i) - 1
        page = 0 if page < 0
        limit = context_options[:per_page].blank? ? 100 : context_options[:per_page].to_i
        offset = page * limit

        current_account = context.current_account
        
        orders = []
        if @options[:order]
          orders << context_options[:order]
        end
        
        options.merge!(:order => orders.join(",")) unless orders.blank? 

        conditions = ["testimonials.approved_at IS NOT NULL"]
        conditions << "testimonials.account_id=#{current_account.id}"

        if @options[:ids]
          ids = context_options[:ids].split(",").map(&:strip).reject(&:blank?)
          ids = ids.map(&:to_i)
          conditions << "testimonials.id IN (#{ids.join(',')})" unless ids.empty?
        end          

        conditions = [conditions.join(" AND ")]
        options.merge!(:conditions => conditions.to_s)
        
        testimonials_count = 0
        
        testimonials = case
                   when @options[:search]
                     q = context_options[:search]
                     Testimonial.search(q, options)
                   when @options[:tagged_all]
                     Testimonial.find_tagged_with(options.merge(:all => Tag.parse(context_options[:tagged_all])))
                   when @options[:tagged_any]
                     Testimonial.find_tagged_with(options.merge(:any => Tag.parse(context_options[:tagged_any])))
                   when @options[:all_testimonials] || @options[:ids]
                     Testimonial.find(:all, options)
                   else
                     raise SyntaxError, "None of search, tagged_any, tagged_all or all_testimonials available"
                   end
                   
        options.delete(:limit)
        options.delete(:offset)
        
        testimonials = testimonials.map do |testimonial|
          pattern = testimonial.patterns.detect {|pattern| context.current_domain.matches?(pattern)}
          testimonial if pattern
        end
        testimonials.compact!
        
        if @options[:randomize]
          context_options[:randomize] = context_options[:randomize].to_i
          context_options[:randomize] = 1 if context_options[:randomize] < 1
          selected_testimonials = testimonials.sort_by {|_| rand}[0, context_options[:randomize]]
        else
          selected_testimonials = testimonials[offset, limit]        
        end
        
        if @options[:pages_count] || @options[:total_count]
          testimonials_count = testimonials.size
          context[@options[:pages_count]] = (testimonials_count / limit).to_i + (testimonials_count % limit > 0 ? 1 : 0)
          context[@options[:total_count]] = testimonials_count
        end
        
        context[@options[:in]] = selected_testimonials
      end
    end
  end
end
