#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  class LoadListings < Liquid::Tag
    PageNumSyntax    = /page_num:\s*(#{Liquid::QuotedFragment})/
    PerPageSyntax    = /per_page:\s*(#{Liquid::QuotedFragment})/
    MlsNoSyntax      = /mls_no:\s*(#{Liquid::QuotedFragment})/
    RealtorSyntax    = /realtor:\s*(#{Liquid::QuotedFragment})/
    StatusSyntax     = /status:\s*(#{Liquid::QuotedFragment})/
    SearchSyntax     = /search:\s*(#{Liquid::QuotedFragment})/
    TaggedAllSyntax  = /tagged_all:\s*(#{Liquid::QuotedFragment})/
    TaggedAnySyntax  = /tagged_any:\s*(#{Liquid::QuotedFragment})/
    OrderSyntax      = /order:\s*(#{Liquid::QuotedFragment})/
    NoOrderByOpenHouseSyntax = /no_order_by_open_house:\s*(#{Liquid::QuotedFragment})/
    OpenHouseSyntax  = /\sopen_house:\s*(#{Liquid::QuotedFragment})/
    RandomizeSyntax  = /randomize:\s*(#{Liquid::QuotedFragment})/
    OwnerEmailSyntax = /owner_email:\s*(#{Liquid::QuotedFragment})/    
    IdsSyntax        = /ids:\s*(#{Liquid::QuotedFragment})/    
    InSyntax         = /in:\s*([\w_]+)/
    AllSyntax        = /all_listings\s*/
    PagesCountSyntax = /pages_count:\s*([\w_]+)/
    TotalCountSyntax = /total_count:\s*([\w_]+)/
    PriceMinSyntax   = /price_min:\s*([\w_]+)/
    PriceMaxSyntax   = /price_max:\s*([\w_]+)/
    BedroomsSyntax   = /bedrooms:\s*(#{Liquid::QuotedFragment})/  
    NearSyntax       = /near:\s*\[(#{Liquid::QuotedFragment})\s*,\s*(#{Liquid::QuotedFragment})\]/

    def initialize(tag_name, markup, tokens)
      super

      @options                = Hash.new
      @options[:page_num]     = $1 if markup =~ PageNumSyntax
      @options[:per_page]     = $1 if markup =~ PerPageSyntax
      @options[:mls_no]       = $1 if markup =~ MlsNoSyntax
      @options[:status]       = $1 if markup =~ StatusSyntax
      @options[:realtor]      = $1 if markup =~ RealtorSyntax
      @options[:search]       = $1 if markup =~ SearchSyntax
      @options[:tagged_all]   = $1 if markup =~ TaggedAllSyntax
      @options[:tagged_any]   = $1 if markup =~ TaggedAnySyntax
      @options[:order]        = $1 if markup =~ OrderSyntax
      @options[:no_order_by_open_house] = true if markup =~ NoOrderByOpenHouseSyntax
      @options[:open_house] = true if markup =~ OpenHouseSyntax
      @options[:price_min]    = $1 if markup =~ PriceMinSyntax
      @options[:price_max]    = $1 if markup =~ PriceMaxSyntax
      @options[:ids]          = $1 if markup =~ IdsSyntax
      @options[:all_listings] = true if markup =~ AllSyntax
      @options[:randomize]    = $1 if markup =~ RandomizeSyntax
      @options[:owner_email]  = $1 if markup =~ OwnerEmailSyntax
      @options[:in]           = $1 if markup =~ InSyntax
      @options[:pages_count]  = $1 if markup =~ PagesCountSyntax
      @options[:total_count]  = $1 if markup =~ TotalCountSyntax
      @options[:bedrooms]     = $1 if markup =~ BedroomsSyntax

      if markup =~ NearSyntax then
        @options[:geo_latitude]  = $1
        @options[:geo_longitude] = $2
      end

      raise SyntaxError, "Missing in: parameter in #{markup.inspect}" unless @options[:in]
      specifications = [@options[:mls_no], @options[:search], @options[:status], @options[:tagged_any], @options[:tagged_all], @options[:all_listings], @options[:ids], @options[:owner_email], @options[:bedrooms]].flatten.compact
      raise SyntaxError, "One of all_listings, mls_no:, status:, search:, tagged_all:, tagged_any:, ids:, or owner_email: must be specified in #{markup.inspect}" if specifications.size < 1
    end

    def render(context)
      returning "" do |buffer|
        options = Hash.new
        context_options = Hash.new
        
        [:page_num, :per_page, :mls_no, :status, :search, :tagged_any, :tagged_all, :order, :price_min, :price_max, :randomize, :owner_email, :ids, :geo_latitude, :geo_longitude, :bedrooms].each do |option_sym|
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
        orders << "open_house DESC" unless @options[:no_order_by_open_house]
        orders << context_options[:order] if @options[:order]
        orders << "mls_no DESC" unless context_options[:order] =~ /mls_no/i
        
        options.merge!(:order => orders.join(",")) 

        conditions = []
        conditions << "listings.account_id=#{current_account.id}"
        if !context.current_user?        
          conditions << "listings.public=1"
        end
        
        if @options[:realtor]
          party_id = case context_options[:realtor]
            when String
              context_options[:realtor].to_i
            when Integer
              context_options[:realtor]
            when Fixnum
              context_options[:realtor]
            when ProfileDrop
              context_options[:realtor].profile.party.id
            end
          conditions << "listings.realtor_id = #{party_id}"
        end
        
        if @options[:price_min]
          conditions << "listings.price_cents >= #{context_options[:price_min].to_s.to_money.cents}"
        end
        
        if @options[:price_max]
          conditions << "listings.price_cents <= #{context_options[:price_max].to_s.to_money.cents}"
        end

        if @options[:ids]
          ids = context_options[:ids].split(",").map(&:strip).reject(&:blank?)
          ids = ids.map(&:to_i)
          conditions << "listings.id IN (#{ids.join(',')})" unless ids.empty?
        end          
        
        if @options[:bedrooms]
          conditions << "listings.raw_property_data LIKE '%total bedrooms: \"#{context_options[:bedrooms].to_s.strip}\"%'" unless context_options[:bedrooms].blank?
        end          
        
        if @options[:open_house]
          conditions << "listings.open_house = 1"
        end

        conditions = [conditions.join(" AND ")]
        options.merge!(:conditions => conditions.to_s)
        
        if @options[:status]
          conditions << "listings.status=?"
          options.merge!(:conditions => [conditions.join(" AND "), context_options[:status].downcase])
          conditions = [options[:conditions]]
        else
          conditions << "(listings.status='Active')"
          conditions = [conditions.join(" AND ")]
          options.merge!(:conditions => conditions.to_s)
        end
        
        if @options[:owner_email]
          context_options[:owner_email].strip!
          context_options[:owner_email].gsub!(/\s+/," ")
          temp = context_options[:owner_email].split(" ")
          value = temp.last
          value.gsub!("'","")
          value.gsub!('"',"")
          operator = if temp.size > 2
              temp[0,2].join(" ")
            else
              temp[0]
            end
          conditions << "listings.contact_email #{operator} ?"                  
          options.merge!(:conditions => [conditions.join(" AND "), value])
          conditions = [options[:conditions]]
        end

        listings_count = 0

        listings_root = if !context_options[:geo_latitude].blank? then
          options.delete(:order)
          Listing.nearest(context_options[:geo_latitude].to_f, context_options[:geo_longitude].to_f, :unit => :kilometers)
        else
          Listing
        end
        
        listings = case
                   when @options[:mls_no]
                     options.delete(:conditions)
                     conditions = ["listings.mls_no=?"]
                     conditions << "listings.public=1" unless context.current_user?
                     listings_root.find(:all, options.merge(:conditions => [conditions.join(" AND "), context_options[:mls_no].upcase]))
                   when @options[:search]
                     q = context_options[:search]
                     listings_root.search(q, options)
                   when @options[:tagged_all]
                     listings_root.find_tagged_with(options.merge(:all => Tag.parse(context_options[:tagged_all])))
                   when @options[:tagged_any]
                     listings_root.find_tagged_with(options.merge(:any => Tag.parse(context_options[:tagged_any])))
                   when @options[:status] || @options[:all_listings] || @options[:ids]
                     listings_root.find(:all, options)
                   else
                     raise SyntaxError, "None of mls_no, all_listings, ids, status, search, category, tagged any or all available"
                   end
                   
        options.delete(:limit)
        options.delete(:offset)
        
        if @options[:randomize]
          context_options[:randomize] = context_options[:randomize].to_i
          context_options[:randomize] = 1 if context_options[:randomize] < 1
          listings = listings.sort_by {|_| rand}[0, context_options[:randomize]]
        end
        
        if @options[:pages_count] || @options[:total_count]
          listings_count = case
                     when @options[:mls_no]
                       options.delete(:conditions)
                       conditions = ["listings.mls_no=?"]
                       conditions << "listings.public=1" unless context.current_user?
                       listings_root.count(:conditions => [conditions.join(" AND "), context_options[:mls_no].upcase])
                     when @options[:search]
                       q = context_options[:search]
                       listings_root.count_results(q, {:conditions => options.delete(:conditions)})
                     when @options[:tagged_all]
                       listings_root.count_tagged_with(options.merge(:all => Tag.parse(context_options[:tagged_all])))
                     when @options[:tagged_any]
                       listings_root.count_tagged_with(options.merge(:any => Tag.parse(context_options[:tagged_any])))
                     when @options[:ids] || @options[:all_listings] || @options[:status]
                       listings_root.count(options)          
                     else
                       raise SyntaxError, "None of mls_no, all_listings, ids, status, search, category, tagged any or all available"
                     end
          context.scopes.last[@options[:pages_count]] = (listings_count / limit).to_i + (listings_count % limit > 0 ? 1 : 0)
          context.scopes.last[@options[:total_count]] = listings_count
        end
        
        context.scopes.last[@options[:in]] = listings
      end
    end
  end
end
