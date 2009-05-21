#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class LayoutsController < ApplicationController
  required_permissions %w(index show new create edit update destroy_collection revisions revision) => :edit_layouts, 
                       %w(async_get_selection) => true
  before_filter :load_layout, :only => %w(show edit update destroy revisions revision)
  before_filter :check_write_access, :only => %w(edit update destroy)

  before_filter :load_source_domains, :only => %w(index)
  
  before_filter :process_layout_params, :only => %w(create update)
  
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
          layouts = current_account.layouts.search(query_params).group_by(&:title).values.map do |group|
            group.best_match_for_domain(@domain)
          end.compact.flatten
          sort = params[:sort].blank? ? :title : params[:sort].to_sym
          dir = params[:dir] if !params[:dir].blank? && params[:dir] =~ /desc/i
          layouts = layouts.sort_by(&sort)
          layouts.reverse! if dir
          logger.debug("^^^starte: #{params[:start]}, limit: #{params[:limit]}")
          @layouts = layouts[params[:start].to_i, params[:limit].to_i]
          logger.debug("^^^layouts #{layouts.size}, @layouts #{@layouts.size}, actual count: #{@layouts_count}")
          @layouts_count = layouts.size
        else
          @layouts = current_account.layouts.search(query_params, search_options)
          @layouts_count = current_account.layouts.count_results(query_params, {})
        end
        render(:json => {:total => @layouts_count, :collection => assemble_records(@layouts)}.to_json)
      end
    end
  end

  def show
    redirect_to edit_layout_path(@layout)
  end

  def new
    @layout = current_account.layouts.build
    respond_to do |format|
      format.html
      format.js
    end
  end

  def edit
    respond_to do |format|
      format.js
    end
  end

  def create
    @layout = current_account.layouts.build(params[:layout])
    @close = true if params[:commit_type] =~ /close/i
    respond_to do |format|
      @layout.creator = @layout.updator = current_user
      @created = @layout.save
      flash[:notice] = 'Layout was successfully created.' if @created
      format.js do
        render_json_response
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
    logger.debug $!.message
      respond_to do |format|
        format.js do
          render_json_response
        end
      end
  end

  def update
    @close = true if params[:commit_type] =~ /close/i
    respond_to do |format|
      @layout.updator = current_user
      @updated = @layout.update_attributes(params[:layout])
      flash[:notice] = @updated ? 'Layout was successfully updated.' : 'Error saving layout: ' + @layout.errors.full_messages.join(',').to_s
      format.js do      
        if params[:from_index]
          render :json => json_response_for(@layout).to_json
        else
          render_json_response
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
          render_json_response
        end
      end
  end
  
  def destroy_collection
    @destroyed_items_size = 0
    current_account.layouts.find(params[:ids].split(",").map(&:strip)).to_a.each do |layout|
      @destroyed_items_size += 1 if layout.destroy
    end
    flash_success :now, "#{@destroyed_items_size} layouts(s) successfully deleted"
    respond_to do |format|
      format.js
    end
  end
  
  def async_get_selection
    layouts = current_account.layouts.find(:all, :order => 'title ASC')
    records = []
    records = layouts.collect { |layout| { 'value' => layout.title, 'id' =>  layout.id.to_s} }
    
    render :json => { 'total' => records.size, 'collection' => records }.to_json
  end

  def revisions
    respond_to do |format|
      format.html
      format.js do
        revisions = []
        @layout.versions.all(:order => "version DESC").each do |v|
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
    temp = @layout.versions.find_by_version(params[:version].to_i)
    RAILS_DEFAULT_LOGGER.debug("^^^aloha im here #{temp.inspect}")
    @revision_layout = Layout.to_new_from_item_version(temp)
    respond_to do |format|
      format.js do
        render :json => @revision_layout.to_json
      end
    end
  end

  protected
  def process_layout_params
    if params[:from_index]
      return unless params[:layout][:no_update_flag]
      no_update_param = params[:layout].delete(:no_update_flag)
      if no_update_param == "1"
        params[:layout][:no_update] = true 
      elsif no_update_param == "0"
        params[:layout][:no_update] = false
      end
    else
      no_update_param = params[:layout].delete(:no_update_flag)
      if no_update_param == "1"
        params[:layout][:no_update] = true 
      else
        params[:layout][:no_update] = false
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
      :content_type => record.content_type,
      :no_update => record.no_update,
      :updator => record.updator ? ( record.updator.full_name.blank? ? record.updator.display_name : record.updator.full_name ) : "Anonymous"
    }
  end
  
  def load_layout
    @layout = current_account.layouts.find(params[:id])
  end

  def layout_title
    @layout.title
  end

  def check_write_access
    return access_denied("Access denied: you may not edit this layout") unless @layout.writeable_by?(current_user)
  end
  
  def json_response_for(snippet)
    json_response = truncate_record(snippet.reload)
    json_response.merge!(:flash => flash[:notice].to_s)
  end
  
  def render_json_response
    errors = "Error: " + (@layout.errors.full_messages.blank? ? ($! ? $!.message : "") : @layout.errors.full_messages.join(',')).to_s
    render :json => {:flash => flash[:notice].to_s, :close => @updated && @close, :errors => errors, 
                     :id => @layout.id, :success => @updated || @created}.to_json
  end  
  
  def load_source_domains
    if !params[:domain].blank? then
      @domain = current_account.domains.find_by_name(params[:domain])
    end
    @source_domains = @domain ? [@domain] : current_account.domains.reject {|d| d.name.blank?}
  end
end
