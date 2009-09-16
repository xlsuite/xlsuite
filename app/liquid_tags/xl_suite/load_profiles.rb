#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  class LoadProfiles < Liquid::Tag
    PageNumSyntax = /page_num:\s*(#{Liquid::QuotedFragment})/
    PerPageSyntax = /per_page:\s*(#{Liquid::QuotedFragment})/
    InSyntax = /in:\s*(\w+)/
    GroupSyntax = /group:\s*(#{Liquid::QuotedFragment})/
    TagOptionSyntax = /tag_option:\s*(#{Liquid::QuotedFragment})/
    TagsSyntax = /tags:\s*(#{Liquid::QuotedFragment})/
    DomainNamesSyntax = /domain_names:\s*(#{Liquid::QuotedFragment})/
    OrderSyntax = /order:\s*(#{Liquid::QuotedFragment})/
    PagesCountSyntax = /pages_count:\s*([\w_]+)/
    TotalCountSyntax = /total_count:\s*([\w_]+)/
    CitySyntax = /city:\s*([\w_]+)/
    StateSyntax = /state:\s*([\w_]+)/
    CountrySyntax = /country:\s*([\w_]+)/
    SearchSyntax = /search:\s*(#{Liquid::QuotedFragment})/
    RandomizeSyntax = /randomize:\s*(#{Liquid::QuotedFragment})/
    ExcludeSyntax = /exclude:\s*(#{Liquid::QuotedFragment})/
    OrderByPointSyntax = /order_by_point:\s*(#{Liquid::QuotedFragment})/
    PointDomainSyntax = /point_domain:\s*(#{Liquid::QuotedFragment})/
    PointToYearSyntax = /point_to_year:\s*(#{Liquid::QuotedFragment})/
    PointToMonthSyntax = /point_to_month:\s*(#{Liquid::QuotedFragment})/
    PointFromYearSyntax = /point_from_year:\s*(#{Liquid::QuotedFragment})/
    PointFromMonthSyntax = /point_from_month:\s*(#{Liquid::QuotedFragment})/

    def initialize(tag_name, markup, tokens)
      super

      @options = Hash.new
      @options[:in] = $1 if markup =~ InSyntax
      @options[:page_num] = $1 if markup =~ PageNumSyntax
      @options[:per_page] = $1 if markup =~ PerPageSyntax
      @options[:group] = $1 if markup =~ GroupSyntax
      @options[:tag_option] = $1 if markup =~ TagOptionSyntax
      @options[:tags] = $1 if markup =~ TagsSyntax
      @options[:order] = $1 if markup =~ OrderSyntax
      @options[:pages_count] = $1 if markup =~ PagesCountSyntax
      @options[:total_count] = $1 if markup =~ TotalCountSyntax
      @options[:city] = $1 if markup =~ CitySyntax
      @options[:state] = $1 if markup =~ StateSyntax
      @options[:country] = $1 if markup =~ CountrySyntax
      @options[:search] = $1 if markup =~ SearchSyntax
      @options[:randomize] = $1 if markup =~ RandomizeSyntax
      @options[:exclude] = $1 if markup =~ ExcludeSyntax
      @options[:order_by_point] = $1 if markup =~ OrderByPointSyntax
      @options[:point_domain] = $1 if markup =~ PointDomainSyntax
      @options[:point_to_year] = $1 if markup =~ PointToYearSyntax
      @options[:point_to_month] = $1 if markup =~ PointToMonthSyntax
      @options[:point_from_year] = $1 if markup =~ PointFromYearSyntax
      @options[:point_from_month] = $1 if markup =~ PointFromMonthSyntax
      @options[:domain_names] = $1 if markup =~ DomainNamesSyntax

      raise SyntaxError, "Missing in: parameter in #{markup.inspect}" unless @options[:in]
      if @options[:page_num] || @options[:per_page] then
        raise SyntaxError, "page_num: and per_page: must be specified together in #{markup.inspect}" unless @options[:page_num] && @options[:per_page]
      end
    end

    def render(context)
      current_account = context.current_account
      options = Hash.new
      context_options = Hash.new
      party_ids = nil
      
      [:page_num, :per_page, :group, :search, :tag_option, :tags, :order, :city, :state, :country, :randomize, :exclude,
      :order_by_point, :point_domain, :point_to_year, :point_to_month, :point_from_year, :point_from_month, :domain_names].each do |option_sym|
        context_options[option_sym] = context[@options[option_sym]]
        context_options[option_sym] = @options[option_sym] unless context_options[option_sym]
      end      
      
      page = (context_options[:page_num].blank? ? 1 : context_options[:page_num].to_i) - 1
      page = 0 if page < 0
      limit = context_options[:per_page].blank? ? 100 : context_options[:per_page].to_i
      offset = page * limit
      
      options = {:limit => limit, :offset => offset} unless @options[:randomize]
      if !context_options[:group].blank?
        party_ids = nil
        q = context_options[:group]
        q.split(",").map(&:strip).each do |label|
          group = current_account.groups.find_by_label(label)
          group_party_ids = group ? ActiveRecord::Base.connection.select_values("SELECT `parties`.id FROM `parties` INNER JOIN memberships ON parties.id = memberships.party_id WHERE ((`memberships`.group_id = #{group.id})) AND (archived_at IS NULL) AND (account_id = #{current_account.id})").map(&:to_i) : []
          if party_ids
            party_ids = party_ids & group_party_ids
          else
            party_ids = group_party_ids
          end
        end
      end

      orders = []
      join_on_contact_routes = false
      if context_options[:order]
        context_options[:order] = context_options[:order].split(",").collect do |order_line|
          order_line.split(/\s+/).collect do |s| 
            if !Party.content_columns.map(&:name).include?(s.downcase) && AddressContactRoute.content_columns.map(&:name).include?(s.downcase)
              join_on_contact_routes = true
              "cr." + s
            else
              s
            end
          end.join(" ")
        end.join(",")
        orders << context_options[:order]
      end

      joins = []
      conditions = []
      condition_params = {}
      
      if !context_options[:city].blank? || !context_options[:state].blank? || !context_options[:country].blank? || join_on_contact_routes
        joins << "INNER JOIN contact_routes cr ON cr.routable_id = profiles.id"
        conditions << "cr.routable_type = 'Profile' AND cr.type = 'AddressContactRoute'"
        if !context_options[:city].blank?
          context_options[:city] = context_options[:city].split(/\s*,\s*/).map(&:strip).reject(&:blank?)
          city_conditions = []
          context_options[:city].each_with_index do |city, i|
            city_conditions << "cr.city LIKE :city#{i}"
            condition_params.merge!("city#{i}".to_sym => '%'+city+'%')
          end
          conditions << '(' + city_conditions.join(" OR ") + ')'
        end
        if !context_options[:state].blank?
          context_options[:state] = context_options[:state].split(/\s*,\s*/).map(&:strip).reject(&:blank?)
          state_conditions = []
          context_options[:state].each_with_index do |state, i|
            state = AddressContactRoute::STATES.assoc(state.titleize) ? state.last : state
            state_conditions << "cr.state LIKE :state#{i}"
            condition_params.merge!("state#{i}".to_sym => '%'+state+'%')
          end
          conditions << '(' + state_conditions.join(" OR ") + ')'
        end
        if !context_options[:country].blank?
          context_options[:country] = context_options[:country].split(/\s*,\s*/).map(&:strip).reject(&:blank?)
          country_conditions = []
          context_options[:country].each_with_index do |country, i|
            country = "can" if country =~ /canada/i
            country = "usa" if country =~ /united states/i
            country_conditions << "cr.country LIKE :country#{i}"
            condition_params.merge!("country#{i}".to_sym => '%'+country+'%')
          end
          conditions << '(' + country_conditions.join(" OR ") + ')'
        end
      end

      if @options[:exclude]
        ids = [context_options[:exclude]].flatten.map(&:id)
        ids = ids.map(&:to_i)
        conditions << "profiles.id NOT IN (#{ids.join(',')})" unless ids.empty?
      end
      
      if @options[:tag_option] && @options[:tags] && !context_options[:tag_option].blank? && !context_options[:tags].blank?
        profile_ids = current_account.profiles.find_tagged_with(context_options[:tag_option].to_sym => Tag.parse(context_options[:tags]), :select => "profiles.id" ).map(&:id)  
        conditions << "profiles.id IN (#{profile_ids.empty? ? 0 : profile_ids.join(',')})" 
      end
      
      
      if @options[:order_by_point] && context_options[:order_by_point] =~ /^(a|de)sc$/i
        party_ids = nil
        domain = nil
        domain = Domain.find_by_name(context_options[:point_domain]) if @options[:point_domain]
        if domain
          if @options[:point_from_year] || @options[:point_from_month] || @options[:point_to_month] || @options[:point_to_year]
            start_year = context_options[:point_from_year].blank? ? Time.now.utc.year : context_options[:point_from_year]
            start_month = context_options[:point_from_month].blank? ? Time.now.utc.month : context_options[:point_from_month]
            to_year = context_options[:point_to_year].blank? ? Time.now.utc.year : context_options[:point_to_year]
            to_month = context_options[:point_to_month].blank? ? Time.now.utc.month : context_options[:point_to_month]
            joins << "INNER JOIN parties ON parties.profile_id = profiles.id INNER JOIN party_domain_monthly_points mp ON mp.party_id = parties.id"
            options[:select] = "profiles.*, SUM(mp.own_point) AS point"
            conditions << "mp.domain_id = #{domain.id} AND mp.year >= #{start_year} AND mp.year <= #{to_year} AND mp.month >= #{start_month} AND mp.month <= #{to_month}"
            options[:group] = "mp.party_id"
            orders = ["point #{context_options[:order_by_point]}"]
          else
            options[:select] = "profiles.*, pp.own_point"
            joins << "INNER JOIN parties parties ON parties.profile_id = profiles.id INNER JOIN party_domain_points pp ON pp.party_id = parties.id"
            conditions << "pp.domain_id = #{domain.id}"
            orders = ["pp.own_point #{context_options[:order_by_point]}"]
          end
        else
          joins << "INNER JOIN parties parties ON parties.profile_id = profiles.id"
          options[:select] = "profiles.*, parties.own_point"
          orders = ["own_point #{context_options[:order_by_point]}"]
        end
      end
      options.merge!(:order => orders.join(",")) unless orders.empty?

      if @options[:domain_names]
        domain_names = context_options[:domain_names].split(",").map(&:strip)
        domains = Domain.all(:conditions => {:name => domain_names})
        t_party_ids = []
        domains.each do |domain|
          t_party_ids += Party.available_on_domain_ids(domain)
        end
        t_party_ids.uniq!
        if party_ids
          party_ids = party_ids & t_party_ids
        else
          party_ids = t_party_ids
        end
      end
      
      profile_ids = party_ids ? current_account.parties.find(:all, :conditions => ["profile_id IS NOT NULL AND parties.id IN (?)", party_ids], :select => "parties.profile_id").map(&:profile_id) : 
                                current_account.parties.find(:all, :conditions => "profile_id IS NOT NULL", :select => "parties.profile_id").map(&:profile_id)
      
      conditions << "profiles.id IN (:profile_ids)"
      condition_params.merge!(:profile_ids => profile_ids)

      options.merge!(:conditions => [conditions.join(" AND "), condition_params], :joins => joins.join(" AND "))
      options.merge!(:select => "profiles.*") unless options[:select]

      if @options[:search]
         q = context_options[:search]
         profiles = current_account.profiles.search(q, options)
         if @options[:pages_count] || @options[:total_count]
          options.delete(:limit)
          options.delete(:offset)
          profiles_count = current_account.profiles.count_results(q, options)
        end
      else
        options.delete(:limit)
        options.delete(:offset)
        find_all_profiles = current_account.profiles.find(:all, options.merge(:conditions => [conditions.join(" AND "), condition_params], :joins => joins.join(" AND "), :select => options[:select]))
        if @options[:pages_count] || @options[:total_count]
          profiles_count = find_all_profiles.size
        end
        profiles = find_all_profiles.slice(offset, limit)
      end
      
      if @options[:randomize]        
        context_options[:randomize] = context_options[:randomize].to_i
        context_options[:randomize] = 1 if context_options[:randomize] < 1
        profiles = profiles.sort_by {|_| rand}[0, context_options[:randomize]]
      end
      
      if @options[:pages_count] || @options[:total_count]
        context.scopes.last[@options[:pages_count]] = (profiles_count / limit).to_i + (profiles_count % limit > 0 ? 1 : 0)
        context.scopes.last[@options[:total_count]] = profiles_count
      end
      
      context.scopes.last[@options[:in]] = profiles.map(&:to_liquid)
      "" # Don't render this tag at all
    end
  end
end
