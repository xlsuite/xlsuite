#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

require "ostruct"

class SnippetsController < ApplicationController
  required_permissions :edit_snippets

  before_filter :load_snippet, :only => %w(edit update destroy revisions revision)
  before_filter :move_behavior_values_to_snippets_parameter, :only => %w(create update)
  before_filter :check_write_access, :only => %w(edit update destroy)
  before_filter :load_source_domains, :only => %w(index)
  before_filter :process_snippet_params, :only => %w(update create)

  def index
    respond_to do |format|
      format.js
      format.json do            
        search_options = {:offset => params[:start], :limit => params[:limit]}
        search_options.merge!(:order => params[:sort].blank? ? "title ASC" : "#{params[:sort]} #{params[:dir]}") 
        
        query_params = params[:q]
        unless query_params.blank? 
          query_params = query_params.split(/\s+/)
          query_params = query_params.map {|q| q+"*"}.join(" ")
        end
        if params[:domain] && params[:domain].downcase != "all"
          @domain = current_account.domains.find_by_name(params[:domain])
          snippets = current_account.snippets.search(query_params).group_by(&:title).values.map do |group|
            group.best_match_for_domain(@domain)
          end.compact.flatten
          sort = params[:sort].blank? ? :title : params[:sort].to_sym
          dir = params[:dir] if !params[:dir].blank? && params[:dir] =~ /desc/i
          snippets = snippets.sort_by(&sort)
          snippets.reverse! if dir
          logger.debug("^^^starte: #{params[:start]}, limit: #{params[:limit]}")
          @snippets = snippets[params[:start].to_i, params[:limit].to_i]
          logger.debug("^^^snippets #{snippets.size}, @snippets #{@snippets.size}, actual count: #{@snippets_count}")
          @snippets_count = snippets.size
        else
          @snippets = current_account.snippets.search(query_params, search_options)
          @snippets_count = current_account.snippets.count_results(query_params, {})
        end
        render(:json => {:total => @snippets_count, :collection => assemble_records(@snippets)}.to_json)
      end
    end
  end

  def new
    @snippet = self.current_account.snippets.build
    if params[:id]
      snippet_origin = self.current_account.snippets.find(params[:id])
      @snippet.attributes = snippet_origin.content_attributes 
    end
    @behavior_values = OpenStruct.new(@snippet.behavior_values)
  end

  def create
    Snippet.transaction do
      published_at = params[:snippet][:published_at]      
      params[:snippet][:behavior] = params[:snippet][:behavior].downcase
      @snippet = current_account.snippets.build(params[:snippet])
      if published_at
        if params[:published_at]
          hour = params[:published_at][:hour].to_i
          hour += 12 if params[:published_at][:ampm] =~ /PM/
          published_at = published_at.utc.change(:hour => hour, :min => params[:published_at][:min]) if published_at.respond_to?(:utc)
        end
        @snippet.published_at = published_at
      end
      @snippet.creator = @snippet.updator = current_user
      @snippet.ignore_warnings = params[:ignore_warnings]
      @snippet.save!
      @created = true
      @close = true if params[:commit_type] =~ /close/i
      @behavior_values = OpenStruct.new(@snippet.behavior_values) if !@created
      
      respond_to do |format|
        format.js do
          flash_success :now, "Snippet *#{@snippet.title}* was created."
        end
      end
    end
    rescue SyntaxError
      flash_failure :now, ""
      respond_to do |format|
        format.js
      end
    rescue
      respond_to do |format|
        format.js do
          flash_notice :now, "Error saving snippet: " + [@snippet.errors.full_messages, @snippet.warnings.full_messages].flatten.join(',').to_s
          render_json_response
        end
      end
  end

  def edit
    @behavior_values = OpenStruct.new(@snippet.behavior_values)
    respond_to do |format|
      format.js
    end
  end

  def update
    Snippet.transaction do
      published_at = params[:snippet][:published_at]
      @snippet.updator = current_user
      params[:snippet][:behavior] = params[:snippet][:behavior].downcase if params[:snippet][:behavior]
      @snippet.ignore_warnings = params[:ignore_warnings]
      @snippet.attributes = params[:snippet]
      if published_at
        if params[:published_at]
          hour = params[:published_at][:hour].to_i
          hour += 12 if params[:published_at][:ampm] =~ /PM/
          published_at = published_at.utc.change(:hour => hour, :min => params[:published_at][:min]) if published_at.respond_to?(:utc)
        end
        @snippet.published_at = published_at
      else
        @snippet.published_at = nil if params[:from_index].blank?
      end
      @snippet.save!
      @updated = true
      if @updated 
        CachedPage.force_refresh_on_account!(self.current_account) if params[:force_refresh]
        CachedPage.force_refresh_on_account_fullslug!(self.current_account, params[:force_refresh_with_fullslug]) if params[:force_refresh_with_fullslug]
      end
      respond_to do |format|
        @close = true if params[:commit_type] =~ /close/i
        format.js do
          flash_success :now, "Snippet *#{@snippet.title}* was updated."
          if params[:from_index]
            render :json => json_response_for(@snippet).to_json
          else
            render_json_response
          end
        end
      end
    end
    rescue SyntaxError
      flash_failure :now, ""
      respond_to do |format|
        format.js do
          render_json_response
        end
      end
    rescue
      respond_to do |format|
        format.js do
          flash_notice :now, "Error saving snippet: " + [@snippet.errors.full_messages, @snippet.warnings.full_messages].flatten.join(',').to_s
          if params[:from_index]
            render :json => json_response_for(@snippet).to_json
          else
            render_json_response
          end
        end
      end
  end
  
  # Params: snippet => {:id1 => :body1, :id2 => :body2, etc...}
  def update_collection
    Snippet.transaction do
      unless params[:snippet].blank?
        params[:snippet].stringify_keys.each_pair do |k, v|
          s=current_account.snippets.find(k)
          s.body = v
          s.save!
        end
      end
      CachedPage.force_refresh_on_account!(self.current_account) if params[:force_refresh]
      CachedPage.force_refresh_on_account_fullslug!(self.current_account, params[:force_refresh_with_fullslug]) if params[:force_refresh_with_fullslug]
    end
    respond_to do |format|
      flash_success :now, "#{params[:snippet].size} snippets were updated."
      format.js do
        render(:json => {:success => true, :message => flash[:notice].to_s}.to_json)
      end
      format.html do
        redirect_to params[:next]
      end
    end
  rescue
    respond_to do |format|
      format.js do
        render(:json => {:success => false, :message => $!.message.to_s}.to_json)
      end
      format.html do
        redirect_to params[:return_to]
      end
    end
  end

  def destroy
    @snippet.destroy
    flash_success "Snippet *#{@snippet.title}* was destroyed."
    redirect_to snippets_path
  end

  def behavior
    @snippet = load_snippet rescue current_account.snippets.build
    @snippet.behavior = params[:snippet][:behavior]
    @behavior_values = OpenStruct.new(@snippet.behavior_values)
    render(@snippet.render_edit.reverse_merge(:layout => false))
  end
  
  def destroy_collection
    @destroyed_items_size = 0
    current_account.snippets.find(params[:ids].split(",").map(&:strip)).to_a.each do |snippet|
      @destroyed_items_size += 1 if snippet.destroy
    end
    flash_success :now, "#{@destroyed_items_size} snippet(s) successfully deleted"
    respond_to do |format|
      format.js
    end
  end

  def revisions
    respond_to do |format|
      format.html
      format.js do
        revisions = []
        @snippet.versions.all(:order => "version DESC").each do |v|
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
    temp = @snippet.versions.find_by_version(params[:version].to_i)
    RAILS_DEFAULT_LOGGER.debug("^^^aloha im here #{temp.inspect}")
    @revision_snippet = Snippet.to_new_from_item_version(temp)
    respond_to do |format|
      format.js do
        render :json => @revision_snippet.to_json
      end
    end
  end

  protected
  def process_snippet_params
    if params[:from_index]
      return unless params[:snippet][:no_update_flag]
      no_update_param = params[:snippet].delete(:no_update_flag)
      if no_update_param == "1"
        params[:snippet][:no_update] = true 
      elsif no_update_param == "0"
        params[:snippet][:no_update] = false
      end
    else
      no_update_param = params[:snippet].delete(:no_update_flag)
      if no_update_param == "1"
        params[:snippet][:no_update] = true 
      else
        params[:snippet][:no_update] = false
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
    {
      :id => record.id,
      :object_id => record.dom_id, 
      :title => record.title,
      :domain_patterns => record.domain_patterns,
      :updated_at => record.updated_at.to_s, 
      :behavior => record.behavior,
      :published_at => record.published_at.to_s,
      :no_update => record.no_update,
      :updator => record.updator ? ( record.updator.full_name.blank? ? record.updator.display_name : record.updator.full_name ) : "Anonymous"
    }
  end
  
  def load_snippet
    @snippet = current_account.snippets.find(params[:id])
  end

  def move_behavior_values_to_snippets_parameter
    params[:snippet][:behavior_values] = params.delete(:behavior_values)
  end

  def check_write_access
    return access_denied("Access denied: you may not edit this snippet") unless @snippet.writeable_by?(current_user)
  end
  
  def json_response_for(page)
    json_response = truncate_record(page.reload)
    json_response.merge!(:flash => flash[:notice].to_s )
  end
  
  def render_json_response
    errors = "Error: " + ((@snippet.errors.full_messages.blank? && @snippet.warnings.full_messages.blank?) ? ($! ? $!.message : "")  : [@snippet.errors.full_messages, @snippet.warnings.full_messages].flatten.join(',').to_s)
    recursive = @snippet.warnings.full_messages.join(",").include?("This snippet refers to itself")
    render :json => {:flash => flash[:notice].to_s, :close => @updated && @close, :errors => errors, 
                     :id => @snippet.id, :success => @updated || @created || false, :recursive => recursive }.to_json
  end  
  
  def load_source_domains
    if !params[:domain].blank? then
      @domain = current_account.domains.find_by_name(params[:domain])
    end
    @source_domains = @domain ? [@domain] : current_account.domains.reject {|d| d.name.blank?}
  end
end
