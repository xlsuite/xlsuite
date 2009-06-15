#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  class LoadGroups < Liquid::Tag
    IdsSyntax = /ids:\s*(#{Liquid::QuotedFragment})/
    ParentSyntax = /parent:\s*(#{Liquid::QuotedFragment})/
    AllSyntax = /all_groups\s*/
    TaggedAllSyntax = /tagged_all:\s*(#{Liquid::QuotedFragment})/
    TaggedAnySyntax = /tagged_any:\s*(#{Liquid::QuotedFragment})/
    OrderSyntax = /order:\s*(#{Liquid::QuotedFragment})/
    PublicSyntax = /public:\s*(#{Liquid::QuotedFragment})/
    ExcludeSyntax = /exclude:\s*(#{Liquid::QuotedFragment})/
    PageNumSyntax = /page_num:\s*(#{Liquid::QuotedFragment})/
    PerPageSyntax = /per_page:\s*(#{Liquid::QuotedFragment})/
    PagesCountSyntax = /pages_count:\s*([\w_]+)/
    TotalCountSyntax = /total_count:\s*([\w_]+)/
    PrivateSyntax = /private:\s*(#{Liquid::QuotedFragment})/
    InSyntax = /in:\s*(\w+)/
    
    def initialize(tag_name, markup, tokens)
      begin
      super
      @options = Hash.new
      @options[:ids] = $1 if markup =~ IdsSyntax
      @options[:parent] = $1 if markup =~ ParentSyntax
      @options[:tagged_any] = $1 if markup =~ TaggedAllSyntax
      @options[:tagged_all] = $1 if markup =~ TaggedAnySyntax
      @options[:all_groups] = true if markup =~ AllSyntax
      @options[:order] = $1 if markup =~ OrderSyntax
      # load all the public or private groups:
      @options[:public] = $1 if markup =~ PublicSyntax
      # load all the private groups that the current user have access to:
      @options[:private] = $1 if markup =~ PrivateSyntax
      @options[:exclude] = $1 if markup =~ ExcludeSyntax

      @options[:in] = $1 if markup =~ InSyntax
      @options[:pages_count] = $1 if markup =~ PagesCountSyntax
      @options[:total_count] = $1 if markup =~ TotalCountSyntax

      raise SyntaxError, "Missing in: parameter in #{markup.inspect}" unless @options[:in]
    rescue
      puts $!.message
      puts $!.backtrace
    end
    end
    
    def render(context)
      begin
      returning "" do
        context_options = Hash.new
        
        [:ids, :parent, :tagged_any, :tagged_all, :order, :exclude, :public].each do |option_sym|
          context_options[option_sym] = context[@options[option_sym]]
          context_options[option_sym] = @options[option_sym] unless context_options[option_sym]
        end
        
        page = (context_options[:page_num].blank? ? 1 : context_options[:page_num].to_i) - 1
        page = 0 if page < 0
        limit = context_options[:per_page].blank? ? 100 : context_options[:per_page].to_i
        offset = page * limit

        current_account = context.current_account
        
        options = {:limit => limit, :offset => offset}
        
        orders = []
        if @options[:order]
          orders << context_options[:order]
        end
        
        options.merge!(:order => orders.join(",")) unless orders.blank? 

        conditions = []
        conditions << "groups.account_id=#{current_account.id}"
        
        if @options[:ids]
          ids = context_options[:ids].split(",").map(&:strip).reject(&:blank?)
          ids = ids.map(&:to_i)
          conditions << "groups.id IN (#{ids.join(',')})" unless ids.empty?
        end
        
        if @options[:parent]
          parent = case context_options[:parent]
            when GroupDrop
              context_options[:parent]
            when String
              context_options[:parent].blank? ? nil : current_account.groups.find_by_id(context_options[:parent].to_i)
            else
              nil
            end
          if parent
            conditions << "groups.parent_id = #{parent.id}"
          else
            conditions << "groups.parent_id IS NULL"
          end
        end
        
        if @options[:exclude] || context_options[:exclude].kind_of?(Array)
          exclude_ids = []
          context_options[:exclude].each do |e|
            exclude_ids << case e
              when String
                e.to_i
              when GroupDrop
                e.id
              end
          end
          conditions << "groups.id NOT IN (#{exclude_ids.join(',')})" unless exclude_ids.empty?
        end
        
        if @options[:public]
          if context_options[:public] =~ /true/i
            conditions << "groups.private = 0"
          elsif context_options[:public] =~ /false/i
            conditions << "groups.private = 1"
          end
        end
        
        if @options[:private]
          ids = []
          if context.current_user? 
            party = context.current_user
            
            expiring_groups_ids = party ? ExpiringPartyItem.all(:conditions => {:party_id => party.id, :item_type => "Group"}, :select => 'item_id').map(&:item_id) : []
            
            if expiring_groups_ids.empty?
              conditions << "groups.id IN (0)"
            else
              conditions << "groups.id in (#{expiring_groups_ids.join(',')})"
            end
          else
            conditions << "groups.id IN (0)"
          end
        end
        
        conditions = [conditions.join(" AND ")]
        options.merge!(:conditions => conditions.to_s)

        groups_count = 0

        groups = case
                   when @options[:tagged_all]
                     Group.find_tagged_with(options.merge(:all => Tag.parse(context_options[:tagged_all])))
                   when @options[:tagged_any]
                     Group.find_tagged_with(options.merge(:any => Tag.parse(context_options[:tagged_any])))
                   when @options[:all_groups] || @options[:ids]
                     Group.find(:all, options)
                   else
                     raise SyntaxError, "None of ids, tagged_any, tagged_all or all_groups available"
                   end
                   
        options.delete(:limit)
        options.delete(:offset)

        if @options[:pages_count] || @options[:total_count]
          groups_count = case
                     when @options[:tagged_all]
                       Group.count_tagged_with(options.merge(:all => Tag.parse(context_options[:tagged_all])))
                     when @options[:tagged_any]
                       Group.count_tagged_with(options.merge(:any => Tag.parse(context_options[:tagged_any])))
                     when @options[:all_groups] || @options[:ids]
                       Group.count(options)          
                     else
                       raise SyntaxError, "None of ids, tagged_any, tagged_all or all_groups available"
                     end
          context[@options[:pages_count]] = (groups_count / limit).to_i + (groups_count % limit > 0 ? 1 : 0)
          context[@options[:total_count]] = groups_count
        end
        
        context[@options[:in]] = groups        
      end
      rescue
        puts $!.message
        puts $!.backtrace
      end
    end
  end
end
