#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class LinksController < ApplicationController
  required_permissions %w(index new edit update destroy destroy_collection images) => :edit_link, 
                       %w(create) => :none
  
  before_filter :load_link, :only => %w(edit update images)
  skip_before_filter :login_required, :only => %w(create)
  
  def index
    respond_to do |format|
      format.json do
        search_options = {:offset => params[:start], :limit => params[:limit]}
        search_options.merge!(:order => params[:sort].blank? ? "created_at DESC" : "#{params[:sort]} #{params[:dir]}") 
        
        query_params = params[:q]
        unless query_params.blank? 
          query_params = query_params.split(/\s+/)
          query_params = query_params.map {|q| q+"*"}.join(" ")
        end
    
        @links = current_account.links.search(query_params, search_options)
        @links_count = current_account.links.count_results(query_params)
        
        render :json => {:collection => assemble_records(@links), :total => @links_count}.to_json
      end
      format.js
    end
  end

  def new
    @link = current_account.links.build
    @link.active_at = Date.today
  end

  def create
    approved = params[:link].delete("approved")
    @link = current_account.links.build(params[:link])
    @link.approved = true if current_user? && approved
    @created = @link.save
    respond_to do |format|
      format.html do
        redirect_to_return_to_or_back
      end
      format.js do
        render_json_response
      end
    end
  end

  def edit
    
  end
  
  def update
    approved = params[:link].delete("approved")
    
    @link.attributes = params[:link]
    if approved
      logger.debug("^^^#{approved}")
      approved = false if approved =~ /false/i
      @link.approved = approved
    end
    @updated = @link.save
    if @updated
      flash_success :now, "Link for #{@link.url} successfully updated"
    else
      flash_failure :now, @link.errors.full_messages.join(',')
    end
    respond_to do |format|
      format.html
      format.js do
        if params[:from_index]
          render_json_response_for_index_update
        else
          render_json_response
        end
      end
    end
  end
  
  def destroy
    if @link.destroy
      flash[:notice] = 'Link destroyed'
    else
      flash[:notice] = "Destroy link failed"
    end
    redirect_to links_url    
  end
  
  def destroy_collection
    @destroyed_items_size = 0
    @undestroyed_items_size = 0
    current_account.links.find_all_by_id(params[:ids].split(",").map(&:strip).reject(&:blank?)).each do |link|
      if link.destroy
        @destroyed_items_size += 1
      else
        @undestroyed_items_size += 1
      end
    end

    error_message = []
    error_message << "#{@destroyed_items_size} link(s) successfully deleted" if @destroyed_items_size > 0
    error_message << "#{@undestroyed_items_size} link(s) failed to be destroyed" if @undestroyed_items_size > 0

    flash_success :now, error_message.join(", ")
    respond_to do |format|
      format.js
    end
  end
  
  def images
    @images = @link.images
    respond_to do |format|
      format.js do
        render :json => assemble_images_to_json(@images, {:size => params[:size]})
      end
    end
  end

  protected
  def load_link
    @link = current_account.links.find(params[:id])
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
      :title => record.title,
      :description => record.description,
      :url => record.url,
      :active_at => record.active_at ? record.active_at.strftime(timestamp_format) : "", 
      :inactive_at => record.inactive_at ? record.inactive_at.strftime(timestamp_format) : "", 
      :updated_at => record.updated_at.to_s, 
      :approved => record.approved,
      :tag_list => record.tag_list
    }
  end
  
  def render_json_response
    errors = (@link.errors.full_messages.blank? ? ($! ? $!.message : "")  : render_to_string(:partial => "/shared/error_messages_for", :locals => {:symbol => :link})).to_s
    render :json => {:flash => flash[:notice].to_s, :close => @updated && @close, :errors => errors, 
                     :id => @link.id, :success => @updated || @created }.to_json
  end  
  
  def render_json_response_for_index_update
    render :json => truncate_record(@link.reload).merge(:flash => flash_messages_to_s).to_json
  end  
end
