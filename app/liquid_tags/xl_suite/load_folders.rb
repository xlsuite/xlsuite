#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  class LoadFolders < Liquid::Tag
    PageNumSyntax = /page_num:\s*(#{Liquid::QuotedFragment})/
    PerPageSyntax = /per_page:\s*(#{Liquid::QuotedFragment})/
    SearchSyntax = /search:\s*(#{Liquid::QuotedFragment})/
    TaggedAllSyntax = /tagged_all:\s*(#{Liquid::QuotedFragment})/
    TaggedAnySyntax = /tagged_any:\s*(#{Liquid::QuotedFragment})/
    OrderSyntax = /order:\s*(#{Liquid::QuotedFragment})/
    RandomizeSyntax = /randomize:\s*(#{Liquid::QuotedFragment})/
    IdsSyntax = /ids:\s*(#{Liquid::QuotedFragment})/
    FolderPathSyntax = /folder_path:\s*(#{Liquid::QuotedFragment})/
    AllSyntax = /all_folders\s*/
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
      @options[:folder_path] = $1 if markup =~ FolderPathSyntax
      @options[:all_folders] = true if markup =~ AllSyntax
      @options[:randomize] = $1 if markup =~ RandomizeSyntax
      @options[:exclude] = $1 if markup =~ ExcludeSyntax
      

      @options[:in] = $1 if markup =~ InSyntax
      @options[:pages_count] = $1 if markup =~ PagesCountSyntax
      @options[:total_count] = $1 if markup =~ TotalCountSyntax

      raise SyntaxError, "Missing in: parameter in #{markup.inspect}" unless @options[:in]

      specifications = [@options[:folder_path], @options[:search], @options[:tagged_any], @options[:tagged_all], @options[:all_folders], @options[:ids]].flatten.compact
      raise SyntaxError, "One of folder_path:, search:, tagged_all:, tagged_any:, all_folders, or ids: must be specified in #{markup.inspect}" if specifications.size < 1
    end

    def render(context)
      returning "" do
        options = Hash.new
        context_options = Hash.new

        [:page_num, :per_page, :search, :tagged_any, :tagged_all, :order, :randomize, :ids, :folder_path, :exclude].each do |option_sym|
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
        conditions << "folders.account_id=#{current_account.id}"
        
        if @options[:ids]
          ids = context_options[:ids].split(",").map(&:strip).reject(&:blank?)
          ids = ids.map(&:to_i)
          conditions << "folders.id IN (#{ids.join(',')})" unless ids.empty?
        end

        if @options[:exclude]
          ids = [context_options[:exclude]].flatten.map(&:id)
          ids = ids.map(&:to_i)
          conditions << "folders.id NOT IN (#{ids.join(',')})" unless ids.empty?
        end

        if @options[:folder_path]
          folder = current_account.folders.find_by_path(context_options[:folder_path])
          if folder
            conditions << "folders.parent_id = #{folder.id}"
          else
            if context_options[:folder_path] =~ /root/i
              conditions << "folders.parent_id IS NULL"
            end
          end
        end 

        group_ids = context.current_user? ? context.current_user.groups.find(:all, :select => "groups.id").map(&:id) : []
        folder_ids = current_account.folders.find(:all, :select => "folders.id",
          :joins => [%Q`LEFT JOIN authorizations ON authorizations.object_type="Blog" AND authorizations.object_id=folders.id`, 
              %Q`LEFT JOIN groups ON groups.id=authorizations.group_id`].join(" "), 
          :conditions => "groups.id IS NULL OR groups.id IN (#{group_ids.join(",").blank? ? 0 : group_ids.join(",")})").map(&:id)
        
        if folder_ids.blank?
          context[@options[:pages_count]] = context[@options[:total_count]] = 0
          context[@options[:in]] = nil
          return
        end
        
        conditions = conditions.join(" AND ")

        options.merge!(:conditions => conditions)

        folders_count = 0

        folders = case
                   when @options[:search]
                     q = context_options[:search]
                     Folder.search(q, options)
                   when @options[:tagged_all]
                     Folder.find_tagged_with(options.merge(:all => Tag.parse(context_options[:tagged_all])))
                   when @options[:tagged_any]
                     Folder.find_tagged_with(options.merge(:any => Tag.parse(context_options[:tagged_any])))
                   when @options[:all_folders] || @options[:ids] || @options[:folder_path]
                     Folder.find(:all, options)
                   else
                     raise SyntaxError, "None of search, tagged_any, tagged_all, all_folders, ids, or folder_path  available"
                   end

        options.delete(:limit)
        options.delete(:offset)

        if @options[:randomize]
          context_options[:randomize] = context_options[:randomize].to_i
          context_options[:randomize] = 1 if context_options[:randomize] < 1
          folders = folders.sort_by {|_| rand}[0, context_options[:randomize]]
        end

        if @options[:pages_count] || @options[:total_count]
          folders_count = case
                     when @options[:search]
                       q = context_options[:search]
                       Folder.count_results(q, {:conditions => options.delete(:conditions)})
                     when @options[:tagged_all]
                       Folder.count_tagged_with(options.merge(:all => Tag.parse(context_options[:tagged_all])))
                     when @options[:tagged_any]
                       Folder.count_tagged_with(options.merge(:any => Tag.parse(context_options[:tagged_any])))
                     when @options[:all_folders] || @options[:ids] || @options[:folder_path]
                       Folder.count(options)
                     else
                       raise SyntaxError, "None of search, tagged_any, tagged_all, all_folders, ids, or folder_path available"
                     end
          context.scopes.last[@options[:pages_count]] = (folders_count / limit).to_i + (folders_count % limit > 0 ? 1 : 0)
          context.scopes.last[@options[:total_count]] = folders_count
        end

        context.scopes.last[@options[:in]] = folders
      end
    end
  end
end
