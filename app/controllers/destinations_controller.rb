#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class DestinationsController < ApplicationController
  required_permissions :edit_destinations
  
  before_filter :find_destination, :only => %w(edit update)
  before_filter :convert_price_params_to_money, :only => %w(create update)
  
  helper OrdersHelper
  
  def index
    find_destinations
    respond_to do |format|
      format.js
      format.json do
        wrapper = { :total => @destinations_count, :collection => truncate_records(@destinations)}
        render :json => wrapper.to_json
      end
    end
  end
  
  def new
    @destination = current_account.destinations.build
    respond_to do |format|
      format.js
    end
  end
  
  def create
    @destination = current_account.destinations.build(params[:destination])
    @created = @destination.save
    if @created
      flash_success :now, "Destination for #{@destination.country}, #{@destination.state} successfully created"
    else
      flash_failure :now, @destination.errors.full_messages
    end  
    respond_to do |format|
      format.js
    end
  end
  
  def edit
    respond_to do |format|
      format.js
    end
  end
  
  def update
    @updated = @destination.update_attributes(params[:destination])
    if @updated
      @message = "Destination for #{@destination.country}, #{@destination.state} successfully updated"
    else
      @message = @destination.errors.full_messages
    end  
    respond_to do |format|
      format.js {render :json => json_response_for(@destination).to_json}
    end
  end
  
  def destroy_collection
    @destroyed_items_size = 0
    current_account.destinations.find(params[:ids].split(",").map(&:strip)).to_a.each do |destination|
      @destroyed_items_size += 1 if destination.destroy
    end
    flash_success :now, "#{@destroyed_items_size} destination(s) successfully deleted"
    respond_to do |format|
      format.js
    end
  end
  
  protected
  def find_destination
    @destination = current_account.destinations.find(params[:id])
  end
  
  def find_destinations
    search_options = {:offset => params[:start], :limit => params[:limit]}
    search_options.merge!(:order => params[:sort].blank? ? "country" : "#{params[:sort]} #{params[:dir]}") 
    
    query_params = params[:q]
    unless query_params.blank? 
      query_params = query_params.split(/\s+/)
      query_params = query_params.map {|q| q+"*"}.join(" ")
    end
    
    @destinations = current_account.destinations.search(query_params, search_options)
    @destinations_count = current_account.destinations.count_results(query_params)
  end
  
  def convert_price_params_to_money
    params[:destination][:cost] = params[:destination][:cost].to_money if params[:destination][:cost]
  end
  
  def truncate_records(destinations)
    truncated_records = []
    destinations.each do |destination|  
      truncated_records << truncate_record(destination)
    end
    return truncated_records
  end
  
  def truncate_record(destination)
    {
      'id' => destination.id,
      'country' => destination.country,
      'state' => destination.state,
      'cost' => destination.cost.to_s
    }
  end
  
  def json_response_for(destination)
    json_response = truncate_record(destination.reload)
    json_response.merge!(:flash => @message )
  end
end
