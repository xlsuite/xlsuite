class AffiliateAccountsController < ApplicationController
  skip_before_filter :login_required, :only => [:login, :forgot_password, :confirm_forgot_password]
  required_permissions %w(show update logout change_password) => "current_user?"
  
  def show
    respond_to do |format|
      format.html
    end
  end
  
  def update
    self.current_user.attributes = params[:affiliate_account]
    @updated = self.current_user.save
    respond_to do |format|
      format.js do 
        render(:json => {:success => @updated, :errors => self.current_user.errors.full_messages}.to_json)
      end
    end
  end
  
  def change_password
    begin
      success = self.current_user.change_password!(params[:affiliate_account])
      respond_to do |format|
        format.js do
          render(:json => {:success => true}.to_json)
        end
      end
    rescue XlSuite::AuthenticatedUser::BadAuthentication => e
      respond_to do |format|
        format.js do
          render(:json => {:success => false, :errors => e.message})
        end
      end
    end
  end
  
  def forgot_password
    @affiliate_account = AffiliateAccount.find_by_email_address(params[:email_address])
    if request.post?
      respond_to do |format|
        format.html do
          if @affiliate_account
            flash_success "We have sent you a new password. Please check your email."
            redirect_to login_affiliate_account_path
          else
            flash_failure "We cannot find you in our database"
            redirect_to forgot_password_affiliate_account_path
          end
        end
      end
    else
      respond_to do |format|
        format.html
      end
    end
  end
  
  def login
    if request.post?
      # login attempt
      begin
        self.current_user = AffiliateAccount.authenticate_with_email_and_password!(
            params[:email_address], params[:password])
            
        self.current_user.save
        cookies[self.session_auth_token] = self.current_user.remember_me! if "1" == params[:remember_me]
        
        respond_to do |format|
          format.html do
            redirect_url = params[:next] || affiliate_account_path
            return redirect_to(redirect_url)
          end
          format.js do
            render :json => {:success => true}.to_json
          end
        end

      rescue XlSuite::AuthenticatedUser::AuthenticationException => e
        logger.warn("Affiliate account authentication failed for #{params[:email].inspect} on domain #{current_domain.name.inspect}: #{$!.message}")
        
        respond_to do |format|
          format.html do
            if params[:return_to]
              flash_failure("Email and/or password is incorrect")
              return redirect_to(params[:return_to])
            else
              flash_failure("Email and/or password is incorrect")
              return redirect_to(login_affiliate_account_path)
            end        
          end
          format.js do
            render :json => {:success => false, :messages => $!.message}.to_json
          end
        end
     end
    else
      # render login page
      respond_to do |format|
        format.html
      end
    end
  end
  
  def logout
    redirect_url = request.env['HTTP_REFERER']
    redirect_url = nil if redirect_url =~ /\/admin/i
    redirect_url ||= login_affiliate_account_path
    @logged_in = self.current_user?
    self.current_user.forget_me! if self.current_user?
    self.current_user = nil
    cookies.delete self.session_current_user_id
    cookies.delete self.session_auth_token
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
        render :json => {:success => @logged_in}.to_json 
      end
    end  
  end
  
  protected
  def current_user
    return self.stub_user unless self.current_user?
    returning @_current_user ||= AffiliateAccount.find(session[self.session_current_user_id]) do
      raise AuthenticatedUser::UnknownUser if @_current_user.archived?
    end
  end

  def session_auth_token
    "affiliate_account_auth_token"
  end
  
  def session_current_user_id
    "affiliate_account_id"
  end
  
  def access_denied(message="Unauthorized access not granted")
    self.store_location
    if current_user?
      respond_to do |format|
        format.html do
          return redirect_to(params[:unauthorized_redirect]) if params[:unauthorized_redirect]
          render :template => "shared/rescues/unauthorized", :layout => false, :status => "401 Unauthorized"
        end 
        format.js do
          render :update do |page|
            page << "Ext.Msg.alert('401 Unauthorized', 'You tried to access something to which you don\\'t have access');"
          end
        end
      end
    else
      flash[:notice] = message unless message.blank?
      respond_to do |format|
        format.html do
          if params[:login_redirect]
            redirect_to(params[:login_redirect])
          else
            redirect_to login_affiliate_account_path
          end
        end
        format.js do
          render :update do |page|
            page << "Ext.Msg.alert('Warning', 'You\\'ve been logged out.');"
          end
        end
      end
    end  
    false
  end
  
  def choose_layout
    case self.action_name
    when "show"
      "affiliate-extjs"
    else
      "plain-html"
    end
  end
end
