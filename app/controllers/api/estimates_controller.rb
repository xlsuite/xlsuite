#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

require "base64"

class Api::EstimatesController < ApplicationController
  session :off

  # We don't use XlSuite::AuthenticatedSystem, but rather a custom version.
  # Reusing #required_permissions though.
  skip_before_filter :login_required

  # This replaces #login_required.
  # TODO: Reenable once we have a better solution to post back to the right domain
  # before_filter :api_login_required, :except => %w(index)

  # And this is the actual authorization checking.
  before_filter :check_party_permissions, :except => %w(index)

  # Write an #authorized? implementation that we can use later.
  required_permissions :edit_estimates

  # Used to show readable documentation to callers.
  layout "api"

  def create
    return render(:text => "<error>No estimate data</error>", :status => "400 Bad Request") unless params.has_key?(:estimate)
    respond_to do |format|
      format.xml do
        Estimate.transaction do
          @invoice_to = params[:estimate].delete(:invoice_to)
          if @invoice_to.blank? then
            response.content_type = "application/xml; charset=UTF-8"
            return render(:text => "<error><message>bad request (no invoice_to)</message></error>", :status => "400 Bad Request") 
          end

          # Remove keys that would cause issues in Estimate#create!
          @number   = @invoice_to.delete(:phone_number)
          @email    = @invoice_to.delete(:email)
          @address  = @invoice_to.delete(:address)

          @customer = current_account.parties.find_by_email_address(@email)
          @customer = current_account.parties.create!(@invoice_to) unless @customer

          # Update customer information in our database
          @customer.phones.find_or_create_by_number(@number) unless @number.blank?
          @customer.email_addresses.find_or_create_by_email_address(@email) unless @email.blank?
          @customer.addresses.find_or_create_by_line1(@address) unless @address.blank?

          lines = params[:estimate].delete(:lines)

          @estimate = current_account.estimates.find_by_uuid(params[:estimate][:uuid]) || current_account.estimates.build
          @estimate.attributes = params[:estimate]
          @estimate.invoice_to = @customer
          @estimate.account = current_account
          @estimate.save!

          @estimate.lines.destroy_all
          @estimate.create_lines!(lines) unless lines.blank?
        end

        response.headers["Location"] = api_estimate_url(@estimate)
        render :nothing => true, :status => "201 Created"
      end
    end
  rescue ActiveRecord::RecordInvalid
    logger.warn $!
    render(:text => $!.record.errors.to_xml, :status => "400 Not Acceptable")
  end

  def update
    @estimate = current_account.estimates.find(params[:id])
    @estimate.update_attributes!(params[:estimate])
    respond_to do |format|
      format.xml do
        render :nothing => true, :status => "200 OK"
      end
    end
  rescue ActiveRecord::RecordInvalid
    render(:text => $!.record.errors.to_xml, :status => "400 Not Acceptable")
  end

  protected
  def api_login_required
    authz_header = request.env["HTTP_AUTHORIZATION"]
    if authz_header =~ /Basic\s([A-Za-z0-9]+==)/ then
      userpass = Base64.decode64($1)
      key = userpass.split(":", 2).last
      api_key = current_account.api_keys.find_by_key(key)
      raise NoSuchKey unless api_key

      self.current_user = api_key.party
    else
      raise NoAuthenticationHeader
    end

  rescue NoSuchKey, NoAuthenticationHeader
    returning(false) do
      response.headers["WWW-Authenticate"] = "Basic realm=\"API Access\""
      response.content_type = "application/xml; charset=UTF-8"
      render :text => "<error>Authentication failure -- missing key parameter</error>", :status => "401 Unauthorized"
    end
  end

  def check_party_permissions
    # access_denied unless authorized?
    true # TODO: Reenable authorization checks
  end

  def access_denied
    response.content_type = "application/xml; charset=UTF-8"
    render :text => "<error>Internal authorization missing</error>", :status => "403 Forbidden"
    false
  end

  class NoSuchKey < RuntimeError; end
  class NoAuthenticationHeader < RuntimeError; end
end
