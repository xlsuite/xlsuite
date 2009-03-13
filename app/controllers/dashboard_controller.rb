#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class DashboardController < ApplicationController
  layout :choose_layout
  
  required_permissions \
      %w(blank_landing landing_page) => :edit_own_account

  before_filter :load_cart, :only => %w(blank_landing landing_page)
  
  def blank_landing
    @title = "XLsuite"
  end  
  
  def landing_page
    options = {:current_account => current_account, :current_account_owner => current_account.owner,
      :tags => TagsDrop.new,
      :current_page_url => get_absolute_current_page_url, :cart => @cart,
      :flash => {:errors => flash[:warning], :messages => flash[:message]}.merge(flash[:liquid] || {})}

    request_params = params.clone
    request_params.delete("controller")
    request_params.delete("action")
    request_params.delete("path")
    options.merge!(:params => request_params, :logged_in => current_user?)
    options.merge!(:current_user => current_user) if current_user?
    options.merge!(:layout => false)
    
    render_page = current_account.pages.find_by_domain_and_fullslug(current_domain, current_domain.get_config(:landing_page_fullslug) || "" )
    if render_page
      render_options = render_page.render_on_domain(current_domain, options)
      @landing_page_html = render_to_string(render_options)
    else
      @landing_page_html = ""
    end
    respond_to do |format|
      format.js
    end
  end
  
  protected
  
  def choose_layout
    return "extjs" if params[:action] == "blank_landing"
    super
  end
end
