#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class TemplatesController < ApplicationController
  required_permissions %w(index show) => "current_user?", %w(new create edit update destroy destroy_collection) => :edit_templates
  
  before_filter :find_template, :only => %w(show edit update destroy)
  before_filter :check_own_access, :only => %w(show edit update destroy)
  
  before_filter :load_groups_and_tags, :only => %w(new edit)
  
  def index
    respond_to do |format|
      format.html do
        all_templates = current_account.templates.find_all_accessible_by(current_user, :order => "label ASC")
        items_per_page = params[:show] || ItemsPerPage
        items_per_page = all_templates.size if params[:show] =~ /all/i
        items_per_page = items_per_page.to_i
    
        @pager = ::Paginator.new(all_templates.size, items_per_page) do |offset, limit|
          all_templates[offset..offset+limit]
        end
        
        @page = @pager.page(params[:page])
        @templates = @page.items
      end
      format.js 
      format.json do
        params[:start] = 0 unless params[:start]
        params[:limit] = 50 unless params[:limit]
        
        search_options = {:offset => params[:start], :limit => params[:limit]}
        search_options.merge!(:order => params[:sort].blank? ? "label ASC, updated_at DESC" : "#{params[:sort]} #{params[:dir]}") 
    
        query_params = params[:q]
        unless query_params.blank? 
          query_params = query_params.split(/\s+/)
          query_params = query_params.map {|q| q+"*"}.join(" ")
        end
        
        @_templates = current_account.templates.find_readable_by(current_user, query_params, search_options)
        @_templates_count = current_account.templates.count_readable_by(current_user, query_params)
        
        render :json => {:collection => assemble_records(@_templates), :total => @_templates_count}.to_json
      end
    end
  end
  
  def show
    respond_to do |format|
      format.html { render :text => "Not supposed to be called" }
      format.js
    end
  end
  
  def new
logger.debug("^^^#{params.inspect}")
logger.debug("^^^#{params[:_template].inspect}")
    @_template = current_account.templates.build(params[:_template])
    respond_to do |format|
      format.html
      format.js
    end
  end
  
  def create
    @_template = current_account.templates.build(params[:_template])
    @_template.party = current_user
    @created = @_template.save
    if @created
      flash_success "#{@_template.label} template successfully created"
      respond_to do |format|
        format.html {redirect_to templates_path}
        format.js {render_json_response}
      end
    else
      flash_failure @_template.errors.full_messages
      respond_to do |format|
        format.html {render_action_new}
        format.js {render_json_response}
      end
    end
  end
  
  def edit
    respond_to do |format|
      format.html
      format.js
    end
  end
  
  def update
    @_template.attributes = params[:_template]
    @_template.party = current_user
    @updated = @_template.save
    @close = true if params[:commit_type] && params[:commit_type] =~ /close/i
    if @updated
      flash_success "#{@_template.label} template successfully updated"
      respond_to do |format|
        format.html {redirect_to templates_path}
        format.js {render_json_response}
      end
    else
      flash_failure @_template.errors.full_messages
      respond_to do |format|
        format.html {render_action_edit}
        format.js {render_json_response}
      end
    end
  end
  
  def destroy
    if @_template.destroy
      flash_success "Template successfully destroyed"
    else
      flash_failure "Deleting template failed!"
    end
    redirect_to templates_path
  end
  
  def destroy_collection
    @destroyed_items_size = 0
    @undestroyed_items_size = 0
    current_account.templates.find_all_by_id(params[:ids].split(",").map(&:strip).reject(&:blank?)).each do |template|
      if template.destroy
        @destroyed_items_size += 1
      else
        @undestroyed_items_size += 1
      end
    end

    error_message = []
    error_message << "#{@destroyed_items_size} template(s) successfully deleted" if @destroyed_items_size > 0
    error_message << "#{@undestroyed_items_size} template(s) failed to be destroyed" if @undestroyed_items_size > 0

    flash_success :now, error_message.join(", ")
    respond_to do |format|
      format.js
    end
  end
  
protected
  def load_groups_and_tags
    @groups = current_account.groups.find(:all, :order => "name ASC")
    @tags = current_account.tags(:order => "count DESC, name ASC")
    #@tags = current_account.templates.tags(:order => "count DESC, name ASC")
  end
  
  def find_template
    @_template = current_account.templates.find(params[:id])
  end
  
  def check_own_access
    redirect_to new_session_path unless @_template.writeable_by?(current_user)
  end

  def render_action_new
    load_groups_and_tags
    render :action => :new
  end
  
  def render_action_edit
    load_groups_and_tags
    render :action => :edit
  end
  
  def assemble_records(records)
    results = []
    records.each do |record|
      results << truncate_record(record)
    end
    results
  end
  
  def truncate_record(record)
    timestamp_format = "%m/%d/%Y"
    {
      :id => record.id,
      :label => record.label,
      :description => record.description,
      :subject => record.subject,
      :created_at => record.created_at.to_s, 
      :updated_at => record.updated_at.to_s,
      :last_modified_by => record.party ? record.party.name.to_s : ""
    }
  end
  
  def render_json_response
    logger.debug("^^^updated: #{@updated}; close: #{@close}")
    errors = (@_template.errors.full_messages.blank? ? ($! ? $!.message : "")  : render_to_string(:partial => "/shared/error_messages_for", :locals => {:symbol => :_template})).to_s
    render :json => {:flash => flash[:notice].to_s, :close => @updated && @close, :errors => errors, 
                     :id => @_template.id, :success => @updated || @created || false }.to_json
  end
end
