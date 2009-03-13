#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class UiController < ApplicationController
  skip_before_filter :login_required
  before_filter :get_report
  
  layout false

  def connect
    @groups = current_account.groups.find(:all, :order => "name")
    params[:path] << "index" if params[:path].size < 2
    params[:path].last << "_ui" 
    render :template => params[:path].join("/"),
        :content_type => "text/javascript; encoding=utf-8"
  end
  
  protected
  def get_report
    if params[:report_id]
      @report = current_account.reports.find(params[:report_id])
    end
  end
end
