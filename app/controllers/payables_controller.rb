#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class PayablesController < ApplicationController
  required_permissions "current_user?"
  
  before_filter :load_payable, :only => [:update, :destroy]
  
  def create
    @payable = current_account.payables.create(params[:payable])
    respond_to do |format|
      format.js { render :json => @payable.id.to_json }
    end
  end
  
  def update
    @payable.attributes = params[:payable]
    status = @payable.save
    respond_to do |format|
      format.js { render :json => status.to_json }
    end
  end
  
  def destroy
    status = @payable.destroy
    respond_to do |format|
      format.js { render :json => status.to_json }
    end
  end
  
  protected
  
  def load_payable
    @payable = current_account.payables.find(params[:id])
  end
end
