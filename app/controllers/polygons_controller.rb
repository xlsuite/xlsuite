#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class PolygonsController < ApplicationController
  required_permissions :none
  before_filter :load_polygon, :only => %w(edit update destroy)
  
  def index
    
  end
  
  def new
    @polygon = Polygon.new()
  end
  
  def create
    params[:polygon][:points] = Polygon.str_to_array(params[:polygon][:points])
    @polygon = current_account.polygons.build(params[:polygon])
    @polygon.party = current_user
    @created = @polygon.save
    respond_to do |format|
      format.html
      format.js do
        render :json => {:success => @created, :errors => @polygon.errors.full_messages.join(",")}
      end
    end
  end
  
  def edit
    
  end
  
  def update
    params[:polygon][:points] = Polygon.str_to_array(params[:polygon][:points])
    @updated = @polygon.update_attributes(params[:polygon])
    respond_to do |format|
      format.html
      format.js do
        render :json => {:success => @updated, :errors => @polygon.errors.full_messages.join(",")}
      end
    end
  end
  
  def destroy
    @destroyed = @polygon.destroy
    respond_to do |format|
      format.html
      format.js do
        render :json => {:success => @destroyed, :errors => @polygon.errors.full_messages.join(",")}
      end
    end
  end
  
  protected
  def load_polygon
    @polygon = current_account.polygons.find(params[:id])
  end
end
