#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  class LoadRents < Liquid::Tag
    PageNumSyntax = /page_num:\s*(#{Liquid::QuotedFragment})/
    PerPageSyntax = /per_page:\s*(#{Liquid::QuotedFragment})/
    StatusSyntax = /status:\s*(#{Liquid::QuotedFragment})/
    SearchSyntax = /search:\s*(#{Liquid::QuotedFragment})/
    BedroomsSyntax = /bedrooms:\s*(#{Liquid::QuotedFragment})/
    OrderSyntax = /order:\s*(#{Liquid::QuotedFragment})/
    RandomizeSyntax = /randomize:\s*(#{Liquid::QuotedFragment})/
    OwnerEmailSyntax = /owner_email:\s*(#{Liquid::QuotedFragment})/    
    IdsSyntax = /ids:\s*(#{Liquid::QuotedFragment})/    
    InSyntax = /in:\s*([\w_]+)/
    PagesCountSyntax = /pages_count:\s*([\w_]+)/
    TotalCountSyntax = /total_count:\s*([\w_]+)/
    PriceMinSyntax = /price_min:\s*([\w_]+)/
    PriceMaxSyntax = /price_max:\s*([\w_]+)/

    def initialize(tag_name, markup, tokens)
      super

      @options = Hash.new
      @options[:page_num] = $1 if markup =~ PageNumSyntax
      @options[:per_page] = $1 if markup =~ PerPageSyntax
      @options[:status] = $1 if markup =~ StatusSyntax
      @options[:search] = $1 if markup =~ SearchSyntax
      @options[:bedrooms] = $1 if markup =~ BedroomsSyntax
      @options[:order] = $1 if markup =~ OrderSyntax
      @options[:price_min] = $1 if markup =~ PriceMinSyntax
      @options[:price_max] = $1 if markup =~ PriceMaxSyntax
      @options[:ids] = $1 if markup =~ IdsSyntax
      @options[:randomize] = $1 if markup =~ RandomizeSyntax
      @options[:owner_email] = $1 if markup =~ OwnerEmailSyntax
      @options[:in] = $1 if markup =~ InSyntax
      @options[:pages_count] = $1 if markup =~ PagesCountSyntax
      @options[:total_count] = $1 if markup =~ TotalCountSyntax

      raise SyntaxError, "Missing in: parameter in #{markup.inspect}" unless @options[:in]
    end

    def render(context)
      returning "" do
        options = Hash.new
        context_options = Hash.new
        
        [:page_num, :per_page, :status, :search, :bedrooms, :order, :price_min, :price_max, :randomize, :owner_email, :ids].each do |option_sym|
          context_options[option_sym] = context[@options[option_sym]]
          context_options[option_sym] = @options[option_sym] unless context_options[option_sym]
        end
        
        page = (context_options[:page_num].blank? ? 1 : context_options[:page_num].to_i) - 1
        page = 0 if page < 0
        limit = context_options[:per_page].blank? ? 10 : context_options[:per_page].to_i
        offset = page * limit

        current_account = context.current_account
        
        options = {}
        options = {:limit => limit, :offset => offset} unless @options[:randomize]
        
        orders = []
        if @options[:order]
          orders << context_options[:order]
        end
        orders << "id ASC"
        
        options.merge!(:order => orders.join(",")) 

        conditions = []
        conditions << "listings.account_id=#{current_account.id}"
        if !context.current_user?        
          conditions << "listings.public=1"
        end
        
        unless context_options[:price_min].blank?
          conditions << "listings.price_cents >= #{context_options[:price_min].to_s.to_money.cents}"
        end
        
        unless context_options[:price_max].blank?
          conditions << "listings.price_cents <= #{context_options[:price_max].to_s.to_money.cents}"
        end

        unless context_options[:bedrooms].blank?
          unless context_options[:bedrooms].to_i == 0
            conditions << "listings.raw_property_data LIKE '%Total Bedrooms: \"#{context_options[:bedrooms].strip}\"%'"
          end
        end

        if @options[:ids]
          ids = context_options[:ids].split(",").map(&:strip).reject(&:blank?)
          ids = ids.map(&:to_i)
          conditions << "listings.id IN (#{ids.join(',')})" unless ids.empty?
        end          

        conditions = [conditions.join(" AND ")]
        options.merge!(:conditions => conditions.to_s)
        
        if @options[:status]
          conditions << "listings.status=?"
          options.merge!(:conditions => [conditions.join(" AND "), context_options[:status].downcase])
          conditions = [options[:conditions]]
        else
          conditions << "(listings.status='Sold' OR listings.status='Active')"
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

        rents_count = 0
        
        rents = case
                   when @options[:search]
                     q = context_options[:search]
                     Rent.search(q, options)
                   else
                     Rent.find(:all, options)
                   end
                   
        options.delete(:limit)
        options.delete(:offset)
        
        if @options[:randomize]
          context_options[:randomize] = context_options[:randomize].to_i
          context_options[:randomize] = 1 if context_options[:randomize] < 1
          rents = rents.sort_by {|_| rand}[0, context_options[:randomize]]
        end
        
        if @options[:pages_count] || @options[:total_count]
          rents_count = case
                     when @options[:search]
                       q = context_options[:search]
                       Rent.count_results(q, {:conditions => options.delete(:conditions)})
                     else
                       Rent.count(options)
                     end
          context[@options[:pages_count]] = (rents_count / limit).to_i + (rents_count % limit > 0 ? 1 : 0)
          context[@options[:total_count]] = rents_count
        end
        
        context[@options[:in]] = rents
      end
    end
  end
end
