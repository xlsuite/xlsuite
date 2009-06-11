class AffiliateAccountsController < ApplicationController
  skip_before_filter :login_required, :only => [:login]
  required_permissions %w(show edit update logout) => "current_user?"
  
  def show
  end
  
  def edit
  end
  
  def update
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
  
  def choose_layout
    "plain-html"
  end
  
  protected
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
end
