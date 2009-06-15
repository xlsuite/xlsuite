#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  class LoadAssets < Liquid::Tag
    PageNumSyntax = /page_num:\s*(#{Liquid::QuotedFragment})/
    PerPageSyntax = /per_page:\s*(#{Liquid::QuotedFragment})/
    SearchSyntax = /search:\s*(#{Liquid::QuotedFragment})/
    TaggedAllSyntax = /tagged_all:\s*(#{Liquid::QuotedFragment})/
    TaggedAnySyntax = /tagged_any:\s*(#{Liquid::QuotedFragment})/
    OrderSyntax = /order:\s*(#{Liquid::QuotedFragment})/
    RandomizeSyntax = /randomize:\s*(#{Liquid::QuotedFragment})/
    IdsSyntax = /ids:\s*(#{Liquid::QuotedFragment})/
    FolderPathSyntax = /folder_path:\s*(#{Liquid::QuotedFragment})/
    FromFoldersSyntax = /from_folders:\s*(#{Liquid::QuotedFragment})/
    AllSyntax = /all_assets\s*/
    ExcludeSyntax = /exclude:\s*(#{Liquid::QuotedFragment})/
    PrivateSyntax = /private:\s*(#{Liquid::QuotedFragment})/

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
      @options[:folder_path] = $1 if markup =~ FolderPathSyntax
      @options[:from_folders] = $1 if markup =~ FromFoldersSyntax
      @options[:all_assets] = true if markup =~ AllSyntax
      @options[:randomize] = $1 if markup =~ RandomizeSyntax
      @options[:exclude] = $1 if markup =~ ExcludeSyntax
      @options[:private] = $1 if markup =~ PrivateSyntax

      @options[:in] = $1 if markup =~ InSyntax
      @options[:pages_count] = $1 if markup =~ PagesCountSyntax
      @options[:total_count] = $1 if markup =~ TotalCountSyntax

      raise SyntaxError, "Missing in: parameter in #{markup.inspect}" unless @options[:in]

      specifications = [@options[:from_folders], @options[:folder_path], @options[:search], @options[:tagged_any], @options[:tagged_all], @options[:all_assets], @options[:ids]].flatten.compact
      raise SyntaxError, "One of from_folders:, folder_path:, search:, tagged_all:, tagged_any:, all_assets, or ids: must be specified in #{markup.inspect}" if specifications.size < 1
    end

    def render(context)
      returning "" do
        options = Hash.new
        context_options = Hash.new

        [:page_num, :per_page, :search, :tagged_any, :tagged_all, :order, :randomize, :ids, :folder_path, :from_folders, :exclude, :private].each do |option_sym|
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
        conditions << "assets.account_id=#{current_account.id}"

        if @options[:ids]
          ids = context_options[:ids].split(",").map(&:strip).reject(&:blank?)
          ids = ids.map(&:to_i)
          conditions << "assets.id IN (#{ids.join(',')})" unless ids.empty?
        end

        if @options[:exclude]
          ids = [context_options[:exclude]].flatten.map(&:id)
          ids = ids.map(&:to_i)
          conditions << "assets.id NOT IN (#{ids.join(',')})" unless ids.empty?
        end
        
        if @options[:from_folders]
          ids = [context_options[:from_folders]].flatten.map(&:id)
          ids = ids.map(&:to_i)
          conditions << "assets.folder_id IN (#{ids.join(',')})" unless ids.empty?
        end

        if @options[:folder_path]
          folder = current_account.folders.find_by_path(context_options[:folder_path])
          if folder
            conditions << "assets.folder_id = #{folder.id}"
          else
            if context_options[:folder_path] =~ /root/i
              conditions << "assets.folder_id IS NULL"
            end
          end
        end
        
        if @options[:private]
          ids = []
          if context.current_user?
            party = context.current_user
            
            expiring_assets_ids = party ? ExpiringPartyItem.all(:conditions => {:party_id => party.id, :item_type => "Asset"}, :select => 'item_id').map(&:item_id) : []
            
            if expiring_assets_ids.empty?
              conditions << "assets.id IN (0)"
            else
              conditions << "assets.id in (#{expiring_assets_ids.join(',')})"
            end
          else
            conditions << "assets.id IN (0)"
          end
        end
        
        conditions = conditions.join(" AND ")
        options.merge!(:conditions => conditions)

        assets_count = 0

        assets = case
                   when @options[:search]
                     q = context_options[:search]
                     Asset.search(q, options)
                   when @options[:tagged_all]
                     Asset.find_tagged_with(options.merge(:all => Tag.parse(context_options[:tagged_all])))
                   when @options[:tagged_any]
                     Asset.find_tagged_with(options.merge(:any => Tag.parse(context_options[:tagged_any])))
                   when @options[:all_assets] || @options[:ids] || @options[:folder_path] || @options[:from_folders]
                     Asset.find(:all, options)
                   else
                     raise SyntaxError, "None of search, tagged_any, tagged_all, all_assets, ids, from_folders, or folder_path  available"
                   end
        options.delete(:limit)
        options.delete(:offset)

        if @options[:randomize]
          context_options[:randomize] = context_options[:randomize].to_i
          context_options[:randomize] = 1 if context_options[:randomize] < 1
          assets = assets.sort_by {|_| rand}[0, context_options[:randomize]]
        end
        if @options[:pages_count] || @options[:total_count]
          assets_count = case
                     when @options[:search]
                       q = context_options[:search]
                       Asset.count_results(q, {:conditions => options.delete(:conditions)})
                     when @options[:tagged_all]
                       Asset.count_tagged_with(options.merge(:all => Tag.parse(context_options[:tagged_all])))
                     when @options[:tagged_any]
                       Asset.count_tagged_with(options.merge(:any => Tag.parse(context_options[:tagged_any])))
                     when @options[:all_assets] || @options[:ids] || @options[:folder_path] || @options[:from_folders]
                       Asset.count(options)
                     else
                       raise SyntaxError, "None of search, tagged_any, tagged_all, all_assets, ids, from_folders, or folder_path available"
                     end
          context[@options[:pages_count]] = (assets_count / limit).to_i + (assets_count % limit > 0 ? 1 : 0)
          context[@options[:total_count]] = assets_count
        end
        context[@options[:in]] = assets
      end
    end
  end
end
