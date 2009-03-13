#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class RedirectsController < ApplicationController
  required_permissions :edit_pages

  before_filter :load_source_domains, :only => %w(index update)
  before_filter :load_redirect, :only => %w(edit update destroy)
  before_filter :force_published_status, :only => %w(create update)
  before_filter :set_creator, :only => %w(create update)

  def index
    respond_to do |format|
      format.html
      format.js
      format.json do
        search_options = {:offset => params[:start], :limit => params[:limit]}
        search_options.merge!(:order => params[:sort].blank? ? "fullslug ASC" : "#{params[:sort]} #{params[:dir]}")

        query_params = params[:q]
        unless query_params.blank?
          query_params = query_params.split(/\s+/)
          query_params = query_params.map {|q| q+"*"}.join(" ")
        end
        if params[:domain] && params[:domain].downcase != "all"
          @domain = current_account.domains.find_by_name(params[:domain])
          redirects = current_account.redirects.search(query_params).group_by(&:fullslug).values.map do |group|
            group.best_match_for_domain(@domain)
          end.compact.flatten
          sort = params[:sort].blank? ? :fullslug : params[:sort].to_sym
          dir = params[:dir] if !params[:dir].blank? && params[:dir] =~ /desc/i
          redirects = redirects.sort_by(&sort)
          redirects.reverse! if dir
          @redirects = redirects[params[:start].to_i, params[:limit].to_i]
          @redirects_count = redirects.size
        else
          @redirects = current_account.redirects.search(query_params, search_options)
          @redirects_count = current_account.redirects.count_results(query_params)
        end

        render(:json => {:total => @redirects_count, :collection => assemble_records(@redirects)}.to_json)
      end
    end
  end

  def new
    if params[:id] then
      @redirect = current_account.pages.find(params.delete("id")).full_copy
      @redirect.fullslug = ""
    else
      @redirect = current_account.redirects.build(:http_code => Redirect::DEFAULT_HTTP_CODE)
    end

    @redirect.creator = current_user
    respond_to do |format|
      format.js
    end
  end

  def create
    @redirect = current_account.redirects.build(params[:redirect])
    @redirect.creator = current_user

    Redirect.transaction do
      @created = @redirect.save!
      @close = true if params[:commit_type] =~ /close/i
      flash_success :now, 'Redirect was successfully created.'
      respond_to do |format|
        format.js do
          render_json_response
        end
      end
    end

  rescue
    respond_to do |format|
      format.js do
        render_json_response
      end
    end
  end

  def edit
    respond_to do |format|
      format.js
    end
  end

  def update
    Page.transaction do
      @redirect.creator = current_user
      @updated = @redirect.update_attributes(params[:redirect])
      @close = true if params[:commit_type] =~ /close/i
      refresh = params[:refresh] || false
      flash_success :now, "Redirect was successfully updated"
      respond_to do |format|
        format.js do
          if params[:from_index]
            render :json => json_response_for(@redirect).merge(:refresh => refresh).to_json
          else
            render_json_response
          end
        end
      end
    end
  end

  def destroy
    @redirect.destroy
    redirect_to redirects_path
  end

  def update_collection
    redirects = current_account.redirects.find(:all, :conditions => ["id IN (?)", params[:ids].split(",").map(&:strip).reject(&:blank?).map(&:to_i)])
    redirects.each do |redirect|
      redirect.update_attributes(params[:redirect])
    end
    respond_to do |format|
      format.js
    end
  end

  def destroy_collection
    redirects = current_account.redirects.find(:all, :conditions => ["id IN (?)", params[:ids].split(",").map(&:strip).reject(&:blank?).map(&:to_i)])
    if redirects.all?(&:destroy) then
      flash_success :now, "#{redirects.length} redirect(s) successfully deleted"
    else
      flash_failure :now, "#{redirects.length} redirect(s) were not all deleted"
    end
    respond_to do |format|
      format.js
    end
  end
  
  def import
    @success = false
    if params[:site][:root] =~ /^http:\/\//i
      @future = RedirectsImportFuture.create!(:account => self.current_account ,:owner => self.current_user, :priority => 150,
        :args => { :root => params[:site][:root], :domain_patterns => params[:site][:domain_patterns]})
      @success = true
    end
    respond_to do |format|
      format.js do
        render(:json => {:success => @success}.to_json)
      end
    end
  end

  protected
  def load_redirect
    @redirect = current_account.redirects.find(params[:id])
  end

  def force_published_status
    params[:redirect].merge!(:status => "published")
  end

  def set_creator
    params[:redirect].merge!(:creator => current_user)
  end

  def assemble_records(records)
    records.inject([]) do |memo, record|
      memo << truncate_record(record)
    end
  end

  def truncate_record(record)
    {
      :id => record.id,
      :fullslug => record.fullslug,
      :target => record.target,
      :status => record.status,
      :domain_patterns => record.domain_patterns,
      :http_code_status => record.http_code_status
    }
  end

  def load_source_domains
    if !params[:domain].blank? then
      @domain = current_account.domains.find_by_name(params[:domain])
    end
    @source_domains = @domain ? [@domain] : current_account.domains.reject {|d| d.name.blank?}
  end

  def json_response_for(redirect)
    json_response = truncate_record(redirect.reload)
    json_response.merge!(:flash => flash[:notice] )
  end

  def render_json_response
    errors = "Error: " + (@redirect.errors.full_messages.blank? ? ($! ? $!.message : "") : @redirect.errors.full_messages.join(',')).to_s
    render :json => {:flash => flash[:notice].to_s, :close => @updated && @close, :errors => errors,
      :id => @redirect.id, :success => @updated || @created}.to_json
    end
  end
