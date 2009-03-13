#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class InterestsController < ApplicationController
  before_filter :load_listing
  before_filter :load_party

  def index
    @interests = @listing.interests
  end

  def create
    @listing.interests << @party
  end

  def destroy
    @listing.interests.delete(@party)
  end

  protected
  def load_listing
    @listing = current_account.listings.find(params[:listing_id])
  end

  def load_party
    @party = current_account.listings.find(params[:party_id]) unless params[:party_id].blank?
  end
end
