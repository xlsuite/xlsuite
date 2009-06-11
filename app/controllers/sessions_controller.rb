#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

require "base64"
require "openssl"
require 'zlib'
require 'stringio'

class SessionsController < ApplicationController
  layout "no-column"

  skip_before_filter :login_required, :except => [:google, :destroy]
  required_permissions %w(google destroy) => "current_user?"

  before_filter :redirect_to_landing, :except => [:destroy]

  def index
    new
    render :action => "new"
  end

  def new
    @user = Party.new
  end

  def create
    self.current_user = Party.authenticate_with_account_email_and_password!(
        current_account, params[:user][:email], params[:user][:password])
        
    self.current_user.tag_list = self.current_user.tag_list << "," << params[:tags] unless params[:tags].blank?
    self.current_user.save
    cookies[XlSuite::AuthenticatedSystem::AUTH_TOKEN] = current_user.remember_me! if "1" == params[:remember_me]
    
    respond_to do |format|
      format.html do
        return redirect_to(blank_landing_url) if (current_user == current_domain.account.owner)

        redirect_url = params[:next] || current_domain.get_config("login_redirection") || forum_categories_url
        return redirect_to(redirect_url)
      end
      format.js do
        render :json => {:success => true, :parameters => params}.to_json
      end
    end

    rescue XlSuite::AuthenticatedUser::AuthenticationException
      logger.warn {"Authentication failed for #{params[:user][:email].inspect} on domain #{current_domain.name.inspect}: #{$!.message}"}
      
      respond_to do |format|
        format.html do
          if params[:return_to]
            flash_failure $!.message
            return redirect_to(params[:return_to])
          else
            flash_failure :now, $!.message
            render :action => :new
          end        
        end
        format.js do
          render :json => {:success => false, :messages => $!.message}.to_json
        end
      end
  end

  def destroy
    redirect_url = request.env['HTTP_REFERER']
    redirect_url = nil if redirect_url =~ /\/admin/i
    redirect_url ||= new_session_url
    @logged_in = self.current_user?
    self.current_user.forget_me! if self.current_user?
    self.current_user = nil
    cookies.delete XlSuite::AuthenticatedSystem::CURRENT_USER_ID
    cookies.delete XlSuite::AuthenticatedSystem::AUTH_TOKEN
    if @logged_in
      flash_success "You are logged out"
    else
      flash_failure "You are not logged in"
    end
    
    respond_to do |format|
      format.html do
        return redirect_to(params[:next]) if params[:next]
        redirect_to redirect_url
      end
      format.js do
        render :json => {:success => @logged_in, :parameters => params}.to_json 
      end
    end
  end

  def google
    decoded_request = Base64.decode64(params['SAMLRequest'])
    # either RFC 1951 or 1952 can be used, so we try former and fall back to latter
    @saml_request = inflate_string(decoded_request) rescue @saml_request = gunzip_string(decoded_request)
    @saml_request_doc = REXML::Document.new(@saml_request)
    load_keys
    login = current_user.main_email.email_address.slice(/(.+)@/i, 1)
    @saml_response = SamlResponse.login_success(login, @saml_request_doc, @public_key, @private_key)
  end

  private
  def load_keys
    @private_key = OpenSSL::PKey::RSA.new(File.read("#{RAILS_ROOT}/config/keys/private.pem"))
    @public_key = OpenSSL::PKey::RSA.new(File.read("#{RAILS_ROOT}/config/keys/public.pem"))
  end

  def inflate_string(string)
    return Zlib::Inflate.new(-Zlib::MAX_WBITS).inflate(string)
  end

  def gunzip_string(string)
    Zlib::GzipReader.new(StringIO.new(string)) {|gz| return gz.read }
  end

  def set_default_title
    @title = "Login | XLsuite"
  end

  def redirect_to_landing
    if current_user?
      flash_success "You are already logged in"
      redirect_to blank_landing_url
    end
  end
end
