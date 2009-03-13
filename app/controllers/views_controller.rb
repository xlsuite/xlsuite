#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ViewsController < ApplicationController
  before_filter :find_ar_object, :except => [:upload]
  required_permissions :none
  before_filter :find_listing, :only => [:upload]
  
=begin
  required_permissions %w(index create show edit update destroy import upload) => [:edit_listings]

  before_filter :find_listing
  before_filter :find_view, :except => [:index, :create, :import, :upload]

  def index
  end
  
  def edit
  end
  
  def create
    Picture.transaction do
      params[:view][:file].delete_if(&:blank?).each do |img|
        @listing.import_local_picture!(img)
      end
    end

    respond_to do |format|
      format.html {redirect_to views_path(@listing)}
    end
  end
  
  def import
    remote_urls = params[:view][:remote_urls].split
    remote_urls.each do |url|
      @listing.import_picture_from_uri!(url)
    end
    respond_to do |format|
      format.html {redirect_to views_path(@listing)}
    end
  end
  
  def update
    if @pic.update_attributes(params[:view])
      flash[:notice] = "View #{@pic.name} saved"
      respond_to do |format|
        format.html { redirect_to views_path(@listing)}
      end
    else
      respond_to do |format|
        format.html { render :action => 'edit'}
      end
    end
  end
  
  def destroy
    if @pic.destroy
      respond_to do |format|
        format.js {}
        format.html {redirect_to views_path(@listing)}
      end
    end
  end  

  def upload
    params[:asset].merge!(:owner => current_user)
    params[:asset].delete(:filename) if params[:asset][:filename].blank?
    @asset = current_account.assets.create!(params[:asset])
    @listing.assets << @asset
    respond_to do |format|
      format.html { redirect_to listing_path(@listing) }
      format.js
    end
  end
=end

  def upload
    params[:asset].merge!(:owner => current_user)
    params[:asset].delete(:filename) if params[:asset][:filename].blank?
    @asset = current_account.assets.create!(params[:asset])
    @listing.assets << @asset
    respond_to do |format|
      format.html { redirect_to listing_path(@listing) }
      format.js
    end
  end
  
  def add
    view = @ar_object.views.build(:asset_id => params[:id])
    if params[:classification]
      view.classification = params[:classification]
    end
    view.save!
    render :nothing => true
  end

  def remove
    view = @ar_object.views.find(:first, :conditions => ["asset_id=?", params[:id]])
    view.destroy if view
    render :nothing => true
  end
  
  def reposition
    ids = params[:ids].split(",").map(&:strip).to_a
    ids.reject!{|e| e.blank?}
    positions = params[:positions].split(",").map(&:strip).map(&:to_i).to_a
    positions.reject!{|e| e.blank?}
    ActiveRecord::Base.transaction do
      (0..ids.length-1).each do |i|
        @ar_object.views.find(:first, :conditions => ["asset_id=?", ids[i]]).update_attribute(:position, positions[i]+1)
      end
    end
    render :nothing => true
  end  

  protected
  
  def find_ar_object
    @ar_object = params[:object_type].classify.constantize.find(:first, :conditions => ["id=?", params[:object_id]])
    raise ActiveRecord::RecordNotFound unless @ar_object
  end

  def find_listing
    @listing = current_account.listings.find(params[:listing_id])
  end
  
=begin
    def find_listing
      @listing = current_account.listings.find(params[:listing_id])
    end
    
    def find_view
      @pic ||= @listing.views.find(params[:id])
    end

  def load_session_data
  end
=end
end
