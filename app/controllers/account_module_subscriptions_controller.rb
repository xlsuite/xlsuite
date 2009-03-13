#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class AccountModuleSubscriptionsController < ApplicationController
  required_permissions :none # Check custom implementation of #authorized? as one of the protected access methods
  before_filter :load_account_module_subscription, :only => [:edit, :pay]
  before_filter :load_by_paypal_ipn_custom, :only => [:ipn, :ipn_cancel]
  
  def index
    respond_to do |format|
      format.js
      format.json do
        self.process_index
        render :json => {:collection => self.assemble_records(@acct_mod_subscriptions), :total => @acct_mod_subscriptions_count}.to_json
      end
    end
  end
  
  def new
    respond_to do |format|
      format.js
    end
  end
  
  def create
    respond_to do |format|
      format.js
    end
  end
  
  def edit
    respond_to do |format|
      format.js
    end
  end
  
  def update
    respond_to do |format|
      format.js
    end
  end
  
  def destroy_collection
    respond_to do |format|
      format.js
    end
  end
  
  def ipn
    respond_to do |format|
      format.html do
        begin
          @payable = @acct_mod_subscription.payable

          @payable.complete!(nil, {
            :ipn_request_params => params, 
            :ipn_request_headers => request.env, 
            :response_data => request.raw_post,
            :domain => current_domain,
            :login_url => new_session_url,
            :reset_password_url => reset_password_parties_url,
            :subject_url => nil})

        ensure
          render :nothing => true
        end
      end
    end
  end
  
  def ipn_cancel
    respond_to do |format|
      format.html do
        render :nothing => true
      end
    end
  end
  
  def pay
    respond_to do |format|
      format.js do
        @payment = @acct_mod_subscription.payment
        case @payment.payment_method
        when "paypal"
          options = {
            :return => "http://xlsuite.com/account/subscriptions/thank_you",
            :cancel_return => ipn_cancel_account_module_subscriptions_url,
            :notify_url => ipn_account_module_subscriptions_url}
          result = @payment.start!(self.current_user, options)
          render :json => {:redirect_url => result.first}.to_json
        else # TODO: this case should never happen at all
          raise "This type of payment method has not yet been supported"
        end
      end
    end
  end
  
  protected
  def load_account_module_subscription
    @acct_mod_subscription = AccountModuleSubscription.find(params[:id])
  end
  
  def load_by_paypal_ipn_custom
    @acct_mod_subscription = current_account.account_module_subscriptions.find_by_uuid(params[:custom])
  end

  def assemble_records(records)
    results = []
    records.each do |record|
      results << truncate_record(record)
    end
    results
  end

  def truncate_record(record)
    {
      :id => record.id,
      :subscription_fee => record.subscription_fee.format(:with_currency, :no_blank),
      :setup_fee => record.setup_fee.format(:with_currency, :no_blank),
      :status => record.status.humanize,
      :installed_template_id => record.installed_account_template ? record.installed_account_template.id : nil,
      :installed_template_name => record.installed_account_template_name,
      :installed_template_domain_patterns => record.installed_account_template ? record.installed_account_template.domain_patterns : "",
      :installed_template_updated_at => record.installed_account_template ? record.installed_account_template.updated_at.strftime(DATETIME_STRFTIME_FORMAT) : "",
      :installed_account_modules => record.installed_account_modules.map(&:humanize).join(", "),
      :created_on =>  record.created_at.strftime(DATE_STRFTIME_FORMAT)
    }
  end
  
  def process_index
    if params[:all]
      @acct_mod_subscriptions = AccountModuleSubscription.all
      @acct_mod_subscriptions_count = AccountModuleSubscription.count
    else
      @acct_mod_subscriptions = self.current_account.account_module_subscriptions.all
      @acct_mod_subscriptions_count = self.current_account.account_module_subscriptions.count
    end
  end
  
  def authorized?
    if %w(index new create edit update pay cancel destroy_collection).include?(self.action_name)
      return false unless self.current_user?
      return true if self.current_user_is_master_account_owner?
      return false unless self.current_account.owner.id == self.current_user.id
      return true
    elsif %w(ipn ipn_cancel).include?(self.action_name)
      return true
    else
      return false
    end
  end
end
