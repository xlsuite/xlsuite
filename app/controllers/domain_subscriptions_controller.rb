#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class DomainSubscriptionsController < ApplicationController
  skip_before_filter :login_required, :only => [:ipn]
  required_permissions :none
  before_filter :load_domain_subscription, :only => [:pay]
  
  def ipn
    begin
      ActiveRecord::Base.transaction do
        @payable = Payable.find(params[:custom] || params[:xxxVar2])

        @payable.complete!(nil, {
          :ipn_request_params => params, 
          :ipn_request_headers => request.env, 
          :response_data => request.raw_post,
          :domain => current_domain,
          :login_url => new_session_url,
          :reset_password_url => reset_password_parties_url,
          :subject_url => nil})
          
        # Paypal IPN Parameters Sample: {
        #  "payment_status"=>"Completed", "receiver_id"=>"WSCE46X7GMNCS", "payer_email"=>"harman_1213986715_per@gmail.com", 
        #  "business"=>"nyampo_1213986597_biz@gmail.com", "payment_gross"=>"", "residence_country"=>"CA", 
        #  "receiver_email"=>"nyampo_1213986597_biz@gmail.com", "invoice"=>"20080064", "subscr_id"=>"S-0DB77399667026049", 
        #  "verify_sign"=>"AM.y8Lq5.J8ubXo92dNT3RW1pnPYA5ZFfq4.MRyd.YIbs5xs47Sj4n9Z", "action"=>"create", 
        #  "mc_currency"=>"CAD", "txn_type"=>"subscr_payment", "charset"=>"windows-1252", 
        #  "txn_id"=>"25T95091B80354949", "item_name"=>"First Domain Subscription", 
        #  "controller"=>"ipn", "notify_version"=>"2.4", "payment_fee"=>"", "payer_status"=>"unverified", 
        #  "mc_fee"=>"3.11", "payment_date"=>"09:31:56 Aug 12, 2008 PDT", "first_name"=>"Test", "test_ipn"=>"1", 
        #  "payment_type"=>"instant", "mc_gross"=>"97.00", "payer_id"=>"TDRZDDNVSTT8A", "last_name"=>"User", 
        #  "custom"=>"59", "item_number"=>"20080064"}

        # Copy paypal subscription id to domain subscription
        # An example: "subscr_id"=>"S-0DB77399667026049"
        order = @payable.subject
        domain_subscription = current_account.domain_subscriptions.find_by_order_id(order.id)
        domain_subscription.paypal_subscription_id = params["subscr_id"]
        # Also flag the DomainSubscription#started_at
        domain_subscription.started_at = Time.now.utc
        domain_subscription.save!
      end
    ensure
      render :nothing => true
    end
  end
  
  def pay
    @order = @domain_subscription.order
    unless @order
      respond_to do |format|
        format.html do
          flash_failure "The subscription is free. You do not need to pay for it."
          redirect_to domains_path
        end
      end
    end
    
    @payment = @order.make_payment!("paypal")
    who = current_user? ? current_user : @order.invoice_to
    
    case @payment.payment_method
    when "paypal"
      return_url = params[:return_url].blank? ? "" : params[:return_url].gsub(/__uuid__/i, @order.uuid)
      options = {:return => domains_url, :notify_url => ipn_domain_subscriptions_url}
      result = @payment.start!(who, options)
      return redirect_to(result.first)
    else # TODO: this case should never happen at all
      raise "This type of payment method has not yet been supported"
    end
  end
  
  protected
  
  def load_domain_subscription
    @domain_subscription = current_account.domain_subscriptions.find(params[:id])
  end
end
