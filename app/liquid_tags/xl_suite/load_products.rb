#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  class LoadProducts < Liquid::Tag
    PageNumSyntax = /page_num:\s*(#{Liquid::QuotedFragment})/
    PerPageSyntax = /per_page:\s*(#{Liquid::QuotedFragment})/
    PublicSyntax = /public:\s*(#{Liquid::QuotedFragment})/
    PrivateSyntax = /private:\s*(#{Liquid::QuotedFragment})/
    SearchSyntax = /search:\s*(#{Liquid::QuotedFragment})/
    CategorySyntax = /category:\s*(#{Liquid::QuotedFragment})/
    CategoriesSyntax = /categories:\s*(#{Liquid::QuotedFragment})/
    TaggedAllSyntax = /tagged_all:\s*(#{Liquid::QuotedFragment})/
    TaggedAnySyntax = /tagged_any:\s*(#{Liquid::QuotedFragment})/
    OrderSyntax = /order:\s*(#{Liquid::QuotedFragment})/
    RandomizeSyntax = /randomize:\s*(#{Liquid::QuotedFragment})/
    CreatorIDSyntax = /creator_id:\s*(#{Liquid::QuotedFragment})/
    OwnerIDSyntax = /owner_id:\s*(#{Liquid::QuotedFragment})/
    PurchasedBySyntax = /purchased_by:\s*(#{Liquid::QuotedFragment})/
    AllSyntax = /all_products\s*/
    ExcludeSyntax = /exclude:\s*(#{Liquid::QuotedFragment})/
    InSyntax = /in:\s*(\w+)/

    PagesCountSyntax = /pages_count:\s*([\w_]+)/
    TotalCountSyntax = /total_count:\s*([\w_]+)/

    def initialize(tag_name, markup, tokens)
      super

      @options = Hash.new
      @options[:page_num] = $1 if markup =~ PageNumSyntax
      @options[:per_page] = $1 if markup =~ PerPageSyntax
      @options[:search] = $1 if markup =~ SearchSyntax
      @options[:category] = $1 if markup =~ CategorySyntax
      @options[:categories] = $1 if markup =~ CategoriesSyntax
      @options[:tagged_all] = $1 if markup =~ TaggedAllSyntax
      @options[:tagged_any] = $1 if markup =~ TaggedAnySyntax
      @options[:order] = $1 if markup =~ OrderSyntax
      @options[:private] = $1 if markup =~ PrivateSyntax
      @options[:public] = $1 if markup =~ PublicSyntax
      @options[:in] = $1 if markup =~ InSyntax
      @options[:pages_count] = $1 if markup =~ PagesCountSyntax
      @options[:total_count] = $1 if markup =~ TotalCountSyntax
      @options[:randomize] = $1 if markup =~ RandomizeSyntax
      @options[:creator_id] = $1 if markup =~ CreatorIDSyntax
      @options[:owner_id] = $1 if markup =~ OwnerIDSyntax
      @options[:purchased_by] = $1 if markup =~ PurchasedBySyntax
      @options[:all_products] = true if markup =~ AllSyntax
      @options[:exclude] = $1 if markup =~ ExcludeSyntax

      raise SyntaxError, "Missing in: parameter in #{markup.inspect}" unless @options[:in]

      specifications = [@options[:category], @options[:categories], @options[:search], @options[:tagged_any], @options[:tagged_all], @options[:all_products]].flatten.compact
      raise SyntaxError, "One of all_products, search:, category:, categories:, tagged_all: or tagged_any: must be specified in #{markup.inspect}" if specifications.size < 1
    end

    def render(context)
      returning "" do
        options = Hash.new
        context_options = Hash.new
        
        [:page_num, :per_page, :search, :category, :categories, :tagged_all, :tagged_any, :order, :randomize, :creator_id, :owner_id, :exclude, :purchased_by].each do |option_sym|
          context_options[option_sym] = context[@options[option_sym]]
          context_options[option_sym] = @options[option_sym] unless context_options[option_sym]
        end
        
        current_account = context.current_account
   
        page = (context_options[:page_num].blank? ? 1 : context_options[:page_num].to_i) - 1
        page = 0 if page < 0
        limit = context_options[:per_page].blank? ? 100 : context_options[:per_page].to_i
        offset = page * limit

        conditions = []
        conditions << "products.account_id=#{current_account.id}"
        
        options = {}
        options = {:limit => limit, :offset => offset} unless @options[:randomize]
        
        orders = []
        if @options[:order]
          orders << context_options[:order]
        end

        if @options[:exclude]
          ids = [context_options[:exclude]].flatten.map(&:id)
          ids = ids.map(&:to_i)
          conditions << "products.id NOT IN (#{ids.join(',')})" unless ids.empty?
        end
        
        if @options[:creator_id]
          conditions << "products.creator_id=#{context_options[:creator_id].to_i}"
        end
        
        if @options[:owner_id]
          conditions << "products.owner_id=#{context_options[:owner_id].to_i}"
        end
        
        if @options[:purchased_by]
          ids = []
          party = nil
          case context_options[:purchased_by]
          when String
            party = current_account.parties.find(context_options[:purchased_by].to_i)
          when PartyDrop
            party = context_options[:purchased_by].party
          when ProfileDrop
            party = context_options[:purchased_by].party
          end
          if party            
            products = party.purchased_products
            if products.flatten.compact.empty?
              conditions << "products.id IN (0)"
            else
              conditions << "products.id IN (#{products.map(&:id).join(',')})"
            end
          else
            conditions << "products.id IN (0)"       
          end
        end
        
        if @options[:private]
          conditions << "products.private = 1"
        elsif @options[:public]
          conditions << "products.private = 0"
        end
        
        if @options[:categories]
          ids = [context_options[:categories]].flatten.map(&:id)
          ids = ids.map(&:to_i)
          options.merge!(:joins => "INNER JOIN product_categories_products ON products.id = product_categories_products.product_id")
          conditions << "product_categories_products.product_category_id IN (#{ids.join(',')})" unless ids.empty?
        end
        
        options.merge!(:order => orders.join(",")) unless orders.blank?
        options.merge!(:conditions => conditions.join(" AND "))

        products = case
                   when @options[:search]
                     q = context_options[:search]
                     Product.search(q, options)
                   when @options[:category]
                     category = context_options[:category]
                     current_account.product_categories.find(category).products.find(:all, options)
                   when @options[:tagged_all]
                     Product.find_tagged_with(options.merge(:all => Tag.parse(context_options[:tagged_all])))
                   when @options[:tagged_any]
                     Product.find_tagged_with(options.merge(:any => Tag.parse(context_options[:tagged_any])))
                   when @options[:all_products]
                     Product.find(:all, options)
                   else
                     raise SyntaxError, "None of search, category, tagged any or all available"
                   end
                   
        options.delete(:limit)
        options.delete(:offset)

        if @options[:randomize]
          context_options[:randomize] = context_options[:randomize].to_i
          context_options[:randomize] = 1 if context_options[:randomize] < 1
          products = products.sort_by {|_| rand}[0, context_options[:randomize]]
        end
        
        if @options[:pages_count] || @options[:total_count]
          products_count = case
                     when @options[:search]
                       q = context_options[:search]
                       Product.count_results(q, {:conditions => options.delete(:conditions)})
                     when @options[:category]
                       category = context_options[:category]
                       current_account.product_categories.find(category).products.count(:conditions => options.delete(:conditions))
                     when @options[:tagged_all]
                       Product.count_tagged_with(options.merge(:all => Tag.parse(context_options[:tagged_all])))
                     when @options[:tagged_any]
                       Product.count_tagged_with(options.merge(:any => Tag.parse(context_options[:tagged_any])))
                     when @options[:all_products]
                       Product.count(:all, options)
                     else
                       raise SyntaxError, "None of search, category, tagged any or all available"
                     end
          context[@options[:pages_count]] = (products_count / limit).to_i + (products_count % limit > 0 ? 1 : 0)
          context[@options[:total_count]] = products_count
        end
        

        context[@options[:in]] = products
      end
    end
  end
end
