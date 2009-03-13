#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ApiKeysController < ApplicationController
  required_permissions :edit_api_keys

  def index
    respond_to do |format|
      format.html
      format.js
      format.json do
        find_api_keys
        render(:json => {:total => @api_keys_count, :collection => assemble_records(@api_keys)}.to_json)
      end
    end
  end

  def create
    @party = current_account.parties.find(params[:party_id] || params[:api_key][:party_id])
    @key = @party.grant_api_access!
    response.headers["Content-Type"] = "text/javascript; charset=UTF-8"
    render :text => {:flash => "API access granted to #{@party}"}.to_json
  rescue ActiveRecord::RecordNotFound
    render :text => "Bad Request", :status => "400 Bad Request"
  end

  def destroy
    destroy_collection
  end

  def destroy_collection
    @count = ApiKey.delete_all(["id IN (?)", params.has_key?(:id) ? [params[:id]] : params[:ids].split(",").map(&:strip)])
    flash_success :now, "Revoked access to the API on #{@count} key#{'s' if @count != 1}"
    respond_to do |format|
      format.js { render :action => "destroy_collection.rjs" }
    end
  end

  protected
  def find_api_keys
    search_options = {:offset => params[:start], :limit => params[:limit]}
    search_options.merge!(:order => "#{params[:sort]} #{params[:dir]}") if params[:sort]

    query_params = params[:q]
    unless query_params.blank? 
      query_params = query_params.split(/\s+/)
      query_params = query_params.map {|q| q+"*"}.join(" ")
    end

    @api_keys = current_account.api_keys.search(query_params, search_options)
    @api_keys_count = current_account.api_keys.count
  end

  def assemble_records(records)
    records.map do |record|
      {:id => record.id, :object_id => record.dom_id, :party_name => record.party_name, :key => record.key}
    end
  end
end
