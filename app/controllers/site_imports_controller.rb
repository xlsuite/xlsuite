#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class SiteImportsController < ApplicationController
  before_filter :check_account_authorization
  required_permissions :edit_pages

  def index
    render :action => :new
  end

  def new
    respond_to do |format|
      format.js
      format.html
    end
  end

  def create
    @future = SiteImportFuture.create!(
      :account => current_account,
      :owner => current_user,
      :args => { :root => params[:site][:root], :title => params[:site][:title], 
                 :domain_patterns => params[:site][:domain_patterns], :slug_match => params[:site][:slug_match] }
    )

    respond_to do |format|
      format.js
      format.html
    end
  end
  
  def check_account_authorization
    return if current_account.options.site_import?
    @authorization = "Site Import"
    access_denied
    false
  end
end
