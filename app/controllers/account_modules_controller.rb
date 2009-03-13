#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class AccountModulesController < ApplicationController
  required_permissions :none
  before_filter :load_account_module, :only => [:update]
  
  def index
    @account_modules = AccountModule.all(:order => "module ASC")
    respond_to do |format|
      format.js
      format.json do
        render(:json => {:collection => self.assemble_records(@account_modules), :total => AccountModule.count}.to_json)
      end
    end
  end
  
  def update
    @account_module.attributes = params[:account_module]
    @updated = @account_module.save
    message = if @updated
        "Pricing for #{@account_module.module.humanize} successfully updated"
      else
        "Something wrong happened"
      end
    respond_to do |format|
      format.js do
        render(:json => (self.truncate_record(@account_module).merge(:flash => message, :success => @updated)).to_json)
      end
    end
  end
  
  protected
  def load_account_module
    @account_module = AccountModule.find(params[:id])
  end
  
  def assemble_records(records)
    result = []
    records.each do |record|
      result << self.truncate_record(record)
    end
    result
  end
  
  def truncate_record(record)
    {
      :id => record.id,
      :minimum_subscription_fee => record.minimum_subscription_fee.to_s,
      :module => record.module.humanize
    }    
  end
  
  def authorized?
    self.current_user_is_master_account_owner?
  end
end
