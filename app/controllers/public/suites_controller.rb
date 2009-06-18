#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Public::SuitesController < ApplicationController
  skip_before_filter :login_required
  before_filter :load_suite, :only => [:show]
  
  def index
    conditions = ["stable_account_id IS NOT NULL"]
    unless params[:ids]
      conditions << "approved_at IS NOT NULL" unless params[:include_unapproved]
    end
    
    if (!params[:main_theme].blank? || !params[:industry].blank?)
      master_acct = Account.find_by_master(true)
      account_template_ids = []
      industry_account_template_ids = []
      main_theme_account_template_ids = []
      
      if params[:main_theme] =~ /^all$/i && params[:industry] =~ /^all$/i
        account_template_ids = nil
      else
        if params[:industry] && params[:industry] !~ /^all$/i
          industry_category = master_acct.categories.find_by_label(params[:industry])
          industry_account_template_ids = Categorizable.all(:conditions => {:subject_type => "AccountTemplate", :category_id => industry_category.id}).map(&:subject_id)
        end
        if params[:main_theme] && params[:main_theme] !~ /^all$/i
          main_theme_category = master_acct.categories.find_by_label(params[:main_theme])
          main_theme_account_template_ids = Categorizable.all(:conditions => {:subject_type => "AccountTemplate", :category_id => main_theme_category.id}).map(&:subject_id)
        end
        if main_theme_account_template_ids.empty? || industry_account_template_ids.empty?
          account_template_ids = main_theme_account_template_ids + industry_account_template_ids
        else
          account_template_ids = main_theme_account_template_ids & industry_account_template_ids
        end
        account_template_ids = [0] if account_template_ids.empty?
        
        conditions << "id IN (#{account_template_ids.join(',')})"
      end
      
      feature_conditions = params.select{|k,v| k =~ /^f_/i && v == "1"}
      feature_conditions.each do |e|
        conditions << (e[0] + " = 1")
      end
    end
    
    if params[:ids]
      suite_ids = params[:ids].split(",").compact.map(&:strip)
      if account_template_ids
        conditions = conditions.reject{|e| e =~ /^id\sin/i}
        suite_ids = account_template_ids & suite_ids
      end
      conditions << "id IN (#{suite_ids.join(',')})"
    end
    
    find_options = {:conditions => conditions.join(" AND ")}
    
    page = (params[:page_num].blank? ? 1 : params[:page_num].to_i) - 1
    page = 0 if page < 0
    limit = params[:per_page].blank? ? ItemsPerPage : params[:per_page].to_i
    offset = params[:start] || (page * limit)
    limit = params[:limit] || limit
    offset = offset.to_i
    limit = limit.to_i
    find_options.merge!(:offset => offset, :limit => limit)

    pages_count = 1
    
    if !params[:tag_list].blank?
      @suites = AccountTemplate.find_tagged_with(find_options.merge(:any => Tag.parse(params[:tag_list])) )
      if limit
        find_options.delete(:offset)
        find_options.delete(:limit)
        @suites_count = AccountTemplate.count_tagged_with(find_options.merge(:any => Tag.parse(params[:tag_list])))
      end
    else
      @suites = AccountTemplate.all(find_options)      
      if limit
        find_options.delete(:offset)
        find_options.delete(:limit)
        @suites_count = AccountTemplate.count(find_options)
      end
    end
    
    pages_count = (@suites_count / limit).to_i + (@suites_count % limit > 0 ? 1 : 0) if limit
    
    respond_to do |format|
      format.json do
        result = []
        @suites.each do |suite|
          next unless suite.trunk_account
          result << self.assemble_record(suite)          
        end
        json_response = {:collection => result, :total => result.size, :pages_count => pages_count}.to_json
        if params[:callback]
          render(:json => "#{params[:callback]}(#{json_response})")
        else
          render(:json => json_response)
        end
      end
    end
  end
  
  def show
    respond_to do |format|
      format.json do
        render(:json => self.assemble_record(@suite).to_json)
      end
    end
  end
  
  def industries
    industries = AccountTemplate.industry_categories
    respond_to do |format|
      format.json do
        result = []
        industries.each do |industry|
          result << {:name =>  industry.name, :label => industry.label}
        end
        json_response = {:collection => result, :total => result.size}.to_json
        if params[:callback]
          render(:json => "#{params[:callback]}(#{json_response})")
        else
          render(:json => json_response)
        end
      end
    end
  end
  
  def main_themes
    main_themes = AccountTemplate.main_theme_categories
    respond_to do |format|
      format.json do
        result = []
        main_themes.each do |main_theme|
          result << {:name =>  main_theme.name, :label => main_theme.label}
        end
        json_response = {:collection => result, :total => result.size}.to_json
        if params[:callback]
          render(:json => "#{params[:callback]}(#{json_response})")
        else
          render(:json => json_response)
        end
      end
    end
  end
  
  def tag_list
    tag_list = AccountTemplate.tags
    result = tag_list.map{|e| {:name => e.name}}
    respond_to do |format|
      format.json do
        json_response = {:collection => result, :total => result.size}.to_json
        if params[:callback]
          render(:json => "#{params[:callback]}(#{json_response})")
        else
          render(:json => json_response)
        end
      end
    end
  end
  
  protected
  def load_suite
    @suite = AccountTemplate.find(params[:id])
  end
  
  def assemble_record(suite)
    {
      :id => suite.id,
      :name => suite.name,
      :demo_url => suite.demo_url,
      :description => suite.description || "N/A",
      :setup_fee => suite.setup_fee.format(:with_currency, :no_blank),
      :subscription_fee => suite.subscription_fee.format(:with_currency, :no_blank),
      :designer_name => suite.designer.display_name.to_s,
      :installed_count => suite.installed_count,
      :rating => "Not implemented",
      :main_image_url => suite.main_image_url,
      :tag_list => suite.tag_list,
      :features_list => suite.features_list,
      :approved => (suite.approved? ? "Yes" : "No"),
      :f_blogs => suite.f_blogs,
      :f_directories => suite.f_directories,
      :f_forums => suite.f_forums,
      :f_product_catalog => suite.f_product_catalog,
      :f_profiles => suite.f_profiles,
      :f_real_estate_listings => suite.f_real_estate_listings,
      :f_rss_feeds => suite.f_rss_feeds,
      :f_testimonials => suite.f_testimonials,
      :f_cms => suite.f_cms,
      :f_workflows => suite.f_workflows
    }
  end
end
