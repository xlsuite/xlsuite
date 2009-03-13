#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Public::InterestsController < ApplicationController
  required_permissions :none
  
  def create
    @listings = current_account.listings.find(params[:ids].split(",").map(&:strip))
    listings = []
    party_listings_ids = current_user.listings.map(&:id)
    listings = @listings.reject{|l| party_listings_ids.include? l.id}
    current_user.listings << listings
    
    listings_added = listings.length
    
    success_message = "#{listings_added} listings added"
    
    respond_to do |format|
      format.html do 
        flash_success success_message
        redirect_to_next_or_back_or_home
      end
      format.js do
        render :json => {:success => true, :flash => success_message}
      end
    end
  end
  
  def destroy_collection
    @listings = current_account.listings.find(params[:ids].split(",").map(&:strip))
    listings_remove_ids = params[:ids].split(",").map(&:strip)
    total = 0
    start = current_user.listings.length
    current_user.interests.clear
    current_user.listings << current_user.listings.reject{|l| listings_remove_ids.include? l.id.to_s}
    total = start - current_user.reload.listings.length
    
    success_message = "#{total} listings removed"
    
    respond_to do |format|
      format.html do 
        flash_success success_message
        redirect_to_next_or_back_or_home
      end
      format.js do
        render :json => {:success => true, :flash => success_message}
      end
    end
  end
end
