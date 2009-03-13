#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Public::DomainsController < ApplicationController
  skip_before_filter :login_required
  
  def check
    taken = (Domain.find_by_name(params[:name]) ? true : false)
    respond_to do |format|
      format.js do
        render(:json => {:taken => taken}.to_json)
      end
    end
  end
end
