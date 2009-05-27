#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  class LoadContactRequests < Liquid::Tag
    PageNumSyntax = /page_num:\s*(#{Liquid::QuotedFragment})/
    PerPageSyntax = /per_page:\s*(#{Liquid::QuotedFragment})/
    SearchSyntax = /search:\s*(#{Liquid::QuotedFragment})/
    TaggedAllSyntax = /tagged_all:\s*(#{Liquid::QuotedFragment})/
    TaggedAnySyntax = /tagged_any:\s*(#{Liquid::QuotedFragment})/
    OrderSyntax = /order:\s*(#{Liquid::QuotedFragment})/
    StatusSyntax = /status:\s*(#{Liquid::QuotedFragment})/
    RandomizeSyntax = /randomize:\s*(#{Liquid::QuotedFragment})/
    IdsSyntax = /ids:\s*(#{Liquid::QuotedFragment})/    
    AffiliatedContactSyntax = /affiliated_contact:\s*(#{Liquid::QuotedFragment})/    
    RecipientContactSyntax = /recipient_contact:\s*(#{Liquid::QuotedFragment})/    
    InSyntax = /in:\s*([\w_]+)/
    AllSyntax = /all_contact_requests\s*/
    PagesCountSyntax = /pages_count:\s*([\w_]+)/
    TotalCountSyntax = /total_count:\s*([\w_]+)/
    ExcludeSyntax = /exclude:\s*(#{Liquid::QuotedFragment})/

    def initialize(tag_name, markup, tokens)
      super

      @options = Hash.new
      @options[:page_num] = $1 if markup =~ PageNumSyntax
      @options[:per_page] = $1 if markup =~ PerPageSyntax
      @options[:search] = $1 if markup =~ SearchSyntax
      @options[:tagged_all] = $1 if markup =~ TaggedAllSyntax
      @options[:tagged_any] = $1 if markup =~ TaggedAnySyntax
      @options[:order] = $1 if markup =~ OrderSyntax
      @options[:status] = $1 if markup =~ StatusSyntax
      @options[:ids] = $1 if markup =~ IdsSyntax
      @options[:affiliated_contact] = $1 if markup =~ AffiliatedContactSyntax
      @options[:recipient_contact] = $1 if markup =~ RecipientContactSyntax
      @options[:all_contact_requests] = true if markup =~ AllSyntax
      @options[:randomize] = $1 if markup =~ RandomizeSyntax
      @options[:exclude] = $1 if markup =~ ExcludeSyntax

      @options[:in] = $1 if markup =~ InSyntax
      @options[:pages_count] = $1 if markup =~ PagesCountSyntax
      @options[:total_count] = $1 if markup =~ TotalCountSyntax

      raise SyntaxError, "Missing in: parameter in #{markup.inspect}" unless @options[:in]

      specifications = [@options[:affiliated_contact], @options[:search], @options[:tagged_any], @options[:tagged_all], @options[:all_contact_requests], @options[:ids]].flatten.compact
      raise SyntaxError, "One of all_contact_requests, affiliated_contact:, search:, tagged_all:, tagged_any:, or ids: must be specified in #{markup.inspect}" if specifications.size < 1
    end

    def render(context)
      returning "" do
        options = Hash.new
        context_options = Hash.new
        
        [:recipient_contact, :affiliated_contact, :page_num, :per_page, :search, :tagged_any, :tagged_all, :order, :randomize, :status, :ids, :exclude].each do |option_sym|
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
        conditions << "contact_requests.account_id=#{current_account.id}"

        if @options[:ids]
          ids = context_options[:ids].split(",").map(&:strip).reject(&:blank?)
          ids = ids.map(&:to_i)
          conditions << "contact_requests.id IN (#{ids.join(',')})" unless ids.empty?
        end      

        if @options[:exclude]
          ids = [context_options[:exclude]].flatten.map(&:id)
          ids = ids.map(&:to_i)
          conditions << "contact_requests.id NOT IN (#{ids.join(',')})" unless ids.empty?
        end
        
        if @options[:status]
          case context_options[:status]
          when /^completed$/i
            status_conditions = {:conditions => ["completed_at < ?", Time.now]}
          when /^incomplete$/i
            status_conditions = {:conditions => ["completed_at IS NULL"]}
          when /^spam$/i
            status_conditions = {:conditions => ["approved_at IS NULL"]}
          else
            status_conditions = {:conditions => ["approved_at IS NOT NULL"]}
          end
          temp_crs = current_account.contact_requests.all(status_conditions)
          ids = temp_crs.map(&:id).map(&:to_i)
            
          if ids.empty?
            context[@options[:pages_count]] = context[@options[:total_count]] = 0
            context[@options[:in]] = nil
            return
          end
          conditions << "contact_requests.id IN (#{ids.join(',')})" unless ids.empty?
        end
        
        contact_request_ids = []
        if @options[:affiliated_contact]
          ids = []
          party = nil
          case context_options[:affiliated_contact]
          when String
            party = current_account.parties.find(context_options[:affiliated_contact].to_i)
          when PartyDrop
            party = context_options[:affiliated_contact].party
          when ProfileDrop
            party = context_options[:affiliated_contact].party
          end
          affiliate_ids = current_account.affiliates.all(:select => "id", :conditions => {:party_id => party.id}).map(&:id)
          unless affiliate_ids.empty?
            contact_request_ids << current_account.contact_requests.all(:select => "id", :conditions => {:affiliate_id => affiliate_ids}).map(&:id)
          end
        end    
        
        if @options[:recipient_contact]
          ids = []
          party = nil
          case context_options[:recipient_contact]
          when String
            party = current_account.parties.find(context_options[:recipient_contact].to_i)
          when PartyDrop
            party = context_options[:recipient_contact].party
          when ProfileDrop
            party = context_options[:recipient_contact].party
          end
          contact_request_ids << ContactRequestRecipient.find_all_by_party_id(party.id).map(&:contact_request_id) if party
        end    

        if @options[:affiliated_contact] || @options[:recipient_contact]
          contact_request_ids = contact_request_ids.flatten.compact
          if contact_request_ids.empty?
            conditions << "contact_requests.id IN (0)"
          else
            conditions << "contact_requests.id in (#{contact_request_ids.join(',')})"
          end 
        end
        
        conditions = [conditions.join(" AND ")]
        options.merge!(:conditions => conditions.to_s)
        
        contact_requests_count = 0
        
        contact_requests = case
                   when @options[:search]
                     q = context_options[:search]
                     ContactRequest.search(q, options)
                   when @options[:tagged_all]
                     ContactRequest.find_tagged_with(options.merge(:all => Tag.parse(context_options[:tagged_all])))
                   when @options[:tagged_any]
                     ContactRequest.find_tagged_with(options.merge(:any => Tag.parse(context_options[:tagged_any])))
                   when @options[:all_contact_requests] || @options[:ids] || @options[:affiliated_contact]
RAILS_DEFAULT_LOGGER.debug("^^^ #{options.inspect}")
RAILS_DEFAULT_LOGGER.debug("^^^ #{ContactRequest.find(:all, options).inspect}")
                     ContactRequest.find(:all, options)
                   else
                     raise SyntaxError, "None of search, tagged_any, tagged_all, affiliated_contact, ids or all_contact_requests available"
                   end
                   
        options.delete(:limit)
        options.delete(:offset)
        
        if @options[:randomize]
          context_options[:randomize] = context_options[:randomize].to_i
          context_options[:randomize] = 1 if context_options[:randomize] < 1
          contact_requests = contact_requests.sort_by {|_| rand}[0, context_options[:randomize]]
        end
        
        if @options[:pages_count] || @options[:total_count]
          contact_requests_count = case
                     when @options[:search]
                       q = context_options[:search]
                       ContactRequest.count_results(q, {:conditions => options.delete(:conditions)})
                     when @options[:tagged_all]
                       ContactRequest.count_tagged_with(options.merge(:all => Tag.parse(context_options[:tagged_all])))
                     when @options[:tagged_any]
                       ContactRequest.count_tagged_with(options.merge(:any => Tag.parse(context_options[:tagged_any])))
                     when @options[:all_contact_requests] || @options[:ids]
                       ContactRequest.count(options)          
                     else
                       raise SyntaxError, "None of search, tagged_any, tagged_all or all_contact_requests available"
                     end
          context[@options[:pages_count]] = (contact_requests_count / limit).to_i + (contact_requests_count % limit > 0 ? 1 : 0)
          context[@options[:total_count]] = contact_requests_count
        end
        
        context[@options[:in]] = contact_requests
      end
    end
  end
  
end
