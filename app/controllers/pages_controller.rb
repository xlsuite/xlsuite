#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

require "ostruct"

class PagesController < ApplicationController
  include ActionView::Helpers::FormTagHelper
  include ActionView::Helpers::FormOptionsHelper
  include ActionView::Helpers::TagHelper

  required_permissions :edit_pages
  skip_before_filter :login_required, :check_account_expiration, :massage_dates_and_times, :find_emails, :reject_unconfirmed_user, :only => [:show, :robots]
  before_filter :load_page_by_id, :only => %w(edit update destroy embed_code revisions revision)
  before_filter :load_layouts, :only => %w(index new edit)
  before_filter :check_write_access, :only => %w(edit update destroy)
  before_filter :load_source_domains, :only => %w(index update)

  before_filter :load_cart, :only => %w(show embed_code)
  before_filter :process_affiliate_tracking, :only => %w(show)
  
  before_filter :process_page_params, :only => %w(create update)

  def sandbox
    respond_to do |format|
      format.html
      format.js
      format.json do
        find_pages
        render :json => JsonCollectionBuilder::build_from_objects(@pages, @pages_count)
      end
    end
  end

  def find_pages_json
    find_pages
    render :json => JsonCollectionBuilder::build_from_objects(@pages, @pages_count)
  end

  def index
    respond_to do |format|
      format.html
      format.js
      format.json do
        search_options = {:offset => params[:start], :limit => params[:limit]}
        search_options.merge!(:order => params[:sort].blank? ? "fullslug ASC" : "#{params[:sort]} #{params[:dir]}")
        conditions = {:conditions => "type != 'Redirect'"}
        search_options.merge!(conditions)

        query_params = params[:q]
        unless query_params.blank?
          query_params = query_params.split(/\s+/)
          query_params = query_params.map {|q| q+"*"}.join(" ")
        end
        if params[:domain] && params[:domain].downcase != "all"
          @domain = current_account.domains.find_by_name(params[:domain])
          pages = current_account.pages.search(query_params).group_by(&:fullslug).values.map do |group|
            group.best_match_for_domain(@domain)
          end.compact.flatten.reject(&:redirect?)
          sort = params[:sort].blank? ? :fullslug : params[:sort].to_sym
          dir = params[:dir] if !params[:dir].blank? && params[:dir] =~ /desc/i
          pages = pages.sort_by(&sort)
          pages.reverse! if dir
          @pages = pages[params[:start].to_i, params[:limit].to_i]
          @pages_count = pages.size
        else
          @pages = current_account.pages.search(query_params, search_options)
          @pages_count = current_account.pages.count_results(query_params, conditions)
        end

        render(:json => {:total => @pages_count, :collection => assemble_records(@pages)}.to_json)
      end
    end
  end

  def show
    allow_access = false
    if @page
      allow_access = @page.published?
      if !allow_access && self.current_user?
        if self.current_user.can?(:edit_pages)
          allow_access = true
        end
        if !allow_access
          allow_access = @page.readable_by?(self.current_user)
        end
      end
      return render(:missing) if !allow_access
    else
      return render(:missing)
    end

    if @page.redirect?
      render_options = @page.render_on_domain(self.current_domain, {})
      render_options.shift
      redirect_to(render_options.first, render_options.last)
    else
      # Look for cached page if user is not logged in and not ssl request and not a POST request
      if !self.current_user? && @page.allow_cache? && !params[:skip_cache] && !self.ssl_required? && !request.post?
        request_uri = request.request_uri.blank? ? "/" : request.request_uri
        cached_page = CachedPage.find(:first, 
          :conditions => ["account_id = ? AND domain_id = ? AND uri = ? AND last_refreshed_at IS NOT NULL", self.current_account.id, self.current_domain.id, request_uri])
        if cached_page
          cached_page.refresh_check!
          @page.http_headers(self.current_domain, {:text => cached_page.rendered_content}).each do |name, value|
            response.headers[name] = value
          end
          return render(:text => cached_page.rendered_content, :content_type => cached_page.rendered_content_type)
        else
          CachedPage.create_from_uri_page_and_domain(request_uri, @page, self.current_domain)
        end
      end
      
      options = {:current_account => self.current_account, :current_account_owner => self.current_account.owner,
        :tags => TagsDrop.new, :user_affiliate_username => self.current_user? ? self.current_user.affiliate_username : "",
        :current_page_url => self.get_absolute_current_page_url, :current_page_slug => self.get_current_page_uri, :cart => @cart,
        :flash => {:errors => flash[:warning], :messages => flash[:message], :notices => flash[:notice]}.merge(flash[:liquid] || {})}

      request_params = params.clone
      request_params.delete("controller")
      request_params.delete("action")
      request_params.delete("path")
      options.merge!(:params => @page_params.merge(request_params), :logged_in => current_user? ? true : false)
      options.merge!(:current_user => self.current_user) if self.current_user?

      # options.merge!(:port => request.env["SERVER_PORT"]) if request.env["SERVER_PORT"] != "80" && RAILS_ENV == "development"
      render_options = @page.render_on_domain(self.current_domain, options)

      # Set HTTP headers according to the page's wishes
      @page.http_headers(self.current_domain, render_options).each do |name, value|
        response.headers[name] = value
      end

      render(render_options)
    end
  end

  def new
    if params[:parent_id] then
      @parent = current_account.pages.find(params[:parent_id])
      @page = @parent.copy
    elsif params[:id] then
      @page = current_account.pages.find(params.delete("id")).full_copy
      @page.fullslug = ""
    else
      @page = current_account.pages.build
    end

    @page.creator = current_user
    @title = "Pages New"
    respond_to do |format|
      format.js
    end
  end

  def edit
    respond_to do |format|
      format.js
    end
  end

  def create
    params[:page][:behavior_values] = params.delete(:behavior_values)
    params[:page][:behavior] = params[:page][:behavior].downcase
    @page = current_account.pages.build(params[:page])
    @page.creator = self.current_user
    @page.updator = self.current_user

    Page.transaction do
      @created = @page.save!
      @close = true if params[:commit_type] =~ /close/i
      flash_success :now, 'Page was successfully created.'
      respond_to do |format|
        format.js do
          render_json_response
        end
        format.xml  { head :created, :location => page_url(@page) }
      end
    end

    rescue SyntaxError
      flash_failure :now, ""
      respond_to do |format|
        format.js do
          render_json_response
        end
        format.xml { render :xml => $!.message.to_xml }
      end
    
    rescue
      @behavior_values = OpenStruct.new(@page.behavior_values)
      respond_to do |format|
        format.js do
          render_json_response
        end
        format.xml  { render :xml => @page.errors.to_xml }
      end
  end

  def update
    Page.transaction do
      @page.updator = current_user
      params[:page][:behavior_values] = params.delete(:behavior_values) if params[:behaviour_values]
      params[:page][:behavior] = params[:page][:behavior].downcase if params[:page][:behavior]
      @updated = @page.update_attributes(params[:page])
      @close = true if params[:commit_type] =~ /close/i
      refresh = params[:refresh] || false
      flash_success :now, "Page was successfully updated"
      respond_to do |format|
        format.js do
          if params[:from_index]
            render :json => json_response_for(@page).merge(:refresh => refresh).to_json
          else
            render_json_response
          end
        end
        format.xml  { head :ok }
      end
    end

    rescue SyntaxError
      flash_failure :now, ""
      respond_to do |format|
        format.js do
          render_json_response
        end
        format.xml { render :xml => $!.message.to_xml }
      end
    
    rescue
      @behavior_values = OpenStruct.new(@page.behavior_values)
      respond_to do |format|
        format.js do
          render_json_response
        end
        format.xml  { render :xml => @page.errors.to_xml }
      end
  end

  def destroy
    if @page.destroy
      respond_to do |format|
        format.html { redirect_to pages_url }
        format.js { render }
        format.xml  { head :ok }
      end
    else
      logger.debug("Coulnd't destroy the page")
      raise "Could not destroy the page"
    end
  end

  def destroy_collection
    @destroyed_items_size = 0
    current_account.pages.find(params[:ids].split(",").map(&:strip)).to_a.each do |page|
      @destroyed_items_size += 1 if page.destroy
    end
    flash_success :now, "#{@destroyed_items_size} page(s) successfully deleted"
    respond_to do |format|
      format.js
    end
  end
  
  def refresh_cached_pages
    if params[:all]
      CachedPage.force_refresh_on_account!(self.current_account)
    else
      CachedPage.force_refresh_on_account_stylesheets!(self.current_account) if params[:stylesheets]
      CachedPage.force_refresh_on_account_javascripts!(self.current_account) if params[:javascripts]
    end
    respond_to do |format|
      format.js do
        render(:json => {:success => true}.to_json)
      end
    end
  end

  def behavior
    @page = load_page_by_id rescue current_account.pages.build
    @page.behavior = params[:page][:behavior]
    @behavior_values = OpenStruct.new(@page.behavior_values)
    render(@page.render_edit.reverse_merge(:layout => false))
  end

  def embed_code
    options = {:current_account => current_account, :current_account_owner => current_account.owner,
      :tags => TagsDrop.new,
      :current_page_url => get_absolute_current_page_url, :cart => @cart,
      :flash => {:errors => flash[:warning], :messages => flash[:message]}.merge(flash[:liquid] || {})}

    request_params = params.clone
    request_params.delete("controller")
    request_params.delete("action")
    request_params.delete("path")
    options.merge!(:params => request_params, :logged_in => current_user? ? true : false)
    options.merge!(:current_user => current_user) if current_user?

    options.merge!(:port => request.env["SERVER_PORT"]) if request.env["SERVER_PORT"] != "80" && RAILS_ENV == "development"
    render_options = @page.render_on_domain(current_domain, options)

    @embed_code = render_options[:text]
    start_index = @embed_code.rindex(/<body>/i) || 0
    end_index = @embed_code.index(/<\/body/i) || 0
    @embed_code = @embed_code[start_index..end_index-1]
    @embed_code.gsub!(/<\/?body>/i, "")

    respond_to do |format|
      format.js
    end
  end
  
  def revisions
    respond_to do |format|
      format.html
      format.js do
        revisions = []
        @page.versions.all(:order => "version DESC").each do |v|
          revisions << {:id => v.id, :version => v.version, :created_at => v.updated_at.to_s, 
            :updator => if (v.updator_id && Party.find_by_id(v.updator_id) &&(Party.find(:first, :conditions => "id = #{v.updator_id}", :select => "parties.account_id").account_id == current_account.id) )
              u = current_account.parties.find(v.updator_id)
              u.full_name.blank? ? u.display_name : u.full_name
            else "Anonymous" end
          }
        end
        render :json => {:total => revisions.size, :collection => revisions}.to_json
      end
    end
  end
  
  def revision
    @revision_page = Page.to_new_from_item_version(@page.versions.find_by_version(params[:version].to_i))
    respond_to do |format|
      format.js do
        render :json => @revision_page.to_json
      end
    end
  end
  
  def robots
    @page = nil
    begin
    self.load_page_by_slug
    rescue ActiveRecord::RecordNotFound
    end
    robots_txt = if @page
        @page.body
      else 
%Q`User-agent: *
Request-rate: 1/7
Crawl-delay: 7`
      end
    render :text => robots_txt, :content_type => "text/plain"
  end
  
  def convert_to_snippet
    @pages = Page.find(params[:ids].split(",").map(&:strip).map(&:to_i))
    failed_pages = []
    @pages.each do |page|
      unless page.convert_to_snippet
        failed_pages = page.fullslug
      end
    end
    respond_to do |format|
      format.js do
        render(:json => {:success => failed_pages.empty?, :failed_pages => failed_pages}.to_json)
      end
    end
  end

  protected
  def process_page_params
    if params[:from_index]
      return unless params[:page][:no_update_flag]
      no_update_param = params[:page].delete(:no_update_flag)
      if no_update_param == "1"
        params[:page][:no_update] = true 
      elsif no_update_param == "0"
        params[:page][:no_update] = false
      end
    else
      require_ssl_param = params[:page].delete(:require_ssl)
      if require_ssl_param == "1"
        params[:page][:require_ssl] = true
      else
        params[:page][:require_ssl] = false
      end
      no_update_param = params[:page].delete(:no_update_flag)
      if no_update_param == "1"
        params[:page][:no_update] = true 
      else
        params[:page][:no_update] = false
      end
    end
  end
  
  def assemble_records(records)
    results = []
    records.each do |record|
      results << truncate_record(record)
    end
    results
  end

  def truncate_record(record)
    domains = @source_domains.select{|domain| record.matches_domain?(domain)}
    selbox = select_tag("page_#{record.id}_domain", "<option>View on domain...</option>\n" + options_from_collection_for_select(domains, :name, :name), :class => "viewer", :onchange => "onViewerChange(this);")
    {
      :id => record.id,
      :title => record.title,
      :fullslug => record.fullslug,
      :status => record.status,
      :behavior => record.behavior,
      :status => record.status,
      :domain_patterns => record.domain_patterns,
      :layout => record.layout,
      :domains => selbox,
      :updator => record.updator ? ( record.updator.full_name.blank? ? record.updator.display_name : record.updator.full_name ) : "Anonymous", 
      :updated_at => record.updated_at.to_s,
      :no_update => record.no_update
    }
  end

  def find_pages
    search_options = {:offset => params[:start], :limit => params[:limit]}
    search_options.merge!(:order => "#{params[:sort]} #{params[:dir]}") if params[:sort]

    query_params = params[:q]
    unless query_params.blank?
      query_params = query_params.split(/\s+/)
      query_params = query_params.map {|q| q+"*"}.join(" ")
    end

    #if current_user.can?(:edit_catalog)
    @pages = current_account.pages.search(query_params, search_options)
    logger.info "@pages = #{@pages.inspect}"
    @pages_count = current_account.pages.count_results(query_params)
    #else
    #  @pages = current_account.pages.find_readable_by(current_user, query_params, search_options)
    #  @pages_count = current_account.pages.count_readable_by(current_user, query_params)
    #end
  end

  def load_page_by_id
    @page = current_account.pages.find(params[:id])
  end

  def page_title
    @page.title
  end

  def load_layouts
    @layouts = current_account.layouts.find_all_by_title
  end

  def check_write_access
    return access_denied("Access denied: you may not edit this page") unless @page.writeable_by?(current_user)
  end

  def load_page_by_slug
    @fullslug = request.env["PATH_INFO"]
    @fullslug.gsub!(/\/\Z/i, "") unless (@fullslug && @fullslug == "/")
    @fullslug = "/" if @fullslug.blank?
    logger.debug {"==> fullslug: #{@fullslug.inspect}"}
    @page, @page_params = self.current_domain.recognize(@fullslug)
  end

  def json_response_for(page)
    json_response = truncate_record(page.reload)
    json_response.merge!(:flash => flash[:notice])
  end

  def load_source_domains
    if !params[:domain].blank? then
      @domain = current_account.domains.find_by_name(params[:domain])
    end
    @source_domains = @domain ? [@domain] : current_account.domains.reject {|d| d.name.blank?}
  end

  def render_json_response
    errors = "Error: " + (@page.errors.full_messages.blank? ? ($! ? $!.message : "") : @page.errors.full_messages.join(',')).to_s
    render :json => {:flash => flash[:notice].to_s, :close => @updated && @close, :errors => errors,
                     :id => @page.id, :success => @updated || @created}.to_json
  end

  # This ssl_required? method overwrites the one in ApplicationController
  def ssl_required?
    ssl_required = if (params[:action] =~ /show/i)
      self.load_page_by_slug
      @page && @page.require_ssl
    else
      (self.class.read_inheritable_attribute(:ssl_required_actions) || []).include?(action_name.to_sym)
    end
    ssl_required && ENV["RAILS_ENV"] == "production"
  end
  
  def process_affiliate_tracking
    unless params[AFFILIATE_IDS_PARAM_KEY].blank?
      affiliate_account = AffiliateAccount.find_by_username(params[AFFILIATE_IDS_PARAM_KEY])
      return true unless affiliate_account
      target_url = self.get_absolute_current_page_url
      referrer_url = request.env["HTTP_REFERER"]
      return true if target_url == referrer_url
      AffiliateAccountTracking.create!(:affiliate_account => affiliate_account, :referrer_url => referrer_url,
        :target_url => target_url, :domain_id => self.current_domain.id, :account_id => self.current_account.id,
        :http_header => request.env, :ip_address => request.env["HTTP_X_FORWARDED_FOR"] || request.remote_ip)
    end
    true
  end

  private
  def ensure_proper_protocol
    return true if self.ssl_allowed?
    if self.ssl_required? && !request.ssl?
      redirect_to("https://" + self.current_account.secure_xlsuite_subdomain + request.request_uri)
      flash.keep
      return false
    elsif request.ssl? && !self.ssl_required?
      redirect_to "http://" + request.host + request.request_uri
      flash.keep
      return false
    end
  end  
end
