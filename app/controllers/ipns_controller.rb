#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class IpnsController < ApplicationController
  skip_before_filter :login_required
  required_permissions :none
  
  skip_before_filter :massage_dates_and_times
  
  def create
    begin
      @payable = current_account.payables.find(params[:custom] || params[:xxxVar2])

      subject = @payable.subject
      subject_url = case subject.class
        when Invoice
          invoice_url(:id => subject.number)
        else
          nil
        end      

      @payable.complete!(nil, {
        :ipn_request_params => params, 
        :ipn_request_headers => request.env, 
        :response_data => request.raw_post,
        :domain => current_domain,
        :login_url => new_session_url,
        :reset_password_url => reset_password_parties_url,
        :subject_url => subject_url})

    ensure
      render :nothing => true
    end
  end
end
