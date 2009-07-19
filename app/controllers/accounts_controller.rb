#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class AccountsController < ApplicationController
  layout :choose_layout

  skip_before_filter :login_required, :only => [:confirm, :activate]
  required_permissions :none # Check custom implementation of #authorized? below
  before_filter :find_account, :only => %w(edit update destroy)
  
  skip_before_filter :block_until_paid_in_full, :only => [:create, :activate]

  before_filter :load_parent_domain, :only => [:confirm]

  def index
    respond_to do |format|
      format.html do
        @total_accounts_number = Account.count
        items_per_page = params[:show] || ItemsPerPage
        items_per_page = @total_accounts_number if params[:show] =~ /all/i
        items_per_page = items_per_page.to_i
        
        @pager = ::Paginator.new(@total_accounts_number, items_per_page) do |offset, limit|
          Account.find(:all, :order => "expires_at", :limit => limit, :offset => offset)
        end
        
        @page = @pager.page(params[:page])
        @accounts = @page.items
      end
      format.json do
        self.find_accounts
        render :json => {:collection => self.assemble_records(@accounts), :total => @accounts_count}.to_json
      end
      format.js
    end
  end

  def new
    @acct = Account.new
    @domain = Domain.new
    @owner = Party.new
    @email = EmailContactRoute.new
    @title = "#{@domain.name} | New Account Registration"
  end

  def create
    @acct = Account.new(params[:account])
    @domain = Domain.new(params[:domain])
    @owner = Party.new(params[:owner])
    @email = EmailContactRoute.new(params[:email])
    
    begin
      Account.transaction do
        @acct.expires_at = Configuration.get(:account_expiration_duration_in_seconds).from_now
        @acct.disable_copy_account_configurations = true
        if @acct.affiliate_usernames.blank? && session[AFFILIATE_IDS_SESSION_KEY]
          @acct.affiliate_usernames = session[AFFILIATE_IDS_SESSION_KEY]
        end
        @acct.save!
        
        @owner.account = @domain.account = @acct
        
        @owner.tag_list = "account-owner"
        @owner.save!

        @domain.valid?

        @email.routable = @owner
        @email.valid?

        @email.save!
        @domain.save!

        @acct.set_parent
        
        @owner.save!
        @owner.reload
        
        @acct.owner = @owner
        @acct.save!
        MethodCallbackFuture.create!(:model => @acct, :method => :grant_all_permissions_to_owner, :account => @acct, :priority => 10)
        
        @acct.copy_profile_to_owner!(:profile_id => params[:profile_id]) if params[:profile_id]

        # We reload the account to refresh the party and contact routes
        # Or else, the email contact route won't be found in account's #send_confirmation_email
        @acct.reload

        # set registering flag here so that confirmation_token is set, do not forget to include confirmation_url
        @acct.registering = true
        confirmation_options = {}
        confirmation_options.merge!(:suite_id => @acct.suite_id) if @acct.suite_id
        @acct.confirmation_url = lambda {|confirmation_token| confirm_accounts_url(confirmation_options.merge(:code => confirmation_token)).gsub(self.current_domain.name, @domain.name)}
        @acct.save!
        return redirect_to params[:next] if params[:next]
      end
    rescue 
      @acct.destroy if @acct.id
      # NOP, let the view handle the details
      logger.warn($!.record) if $!.respond_to?(:record)
      logger.warn($!)
      logger.warn($!.backtrace.join("\n"))
      flash_failure :now, $!.message
      flash_failure $!.message
      return redirect_to params[:return_to] if params[:return_to]
      @_parent_domain = self.get_request_parent_domain
      render :action => :new, :layout => "plain-html"
    end
  end

  def edit
    @domains = @acct.sorted_domains
  end

  def update
    cap_total_asset_size = params[:account].delete(:cap_total_asset_size)
    if cap_total_asset_size
      @acct.cap_total_asset_size = cap_total_asset_size.to_i * 1.megabyte
    end
    cap_asset_size = params[:account].delete(:cap_asset_size)
    if cap_asset_size
      @acct.cap_asset_size = cap_asset_size.to_i * 1.megabyte
    end
    @acct.attributes = params[:account]
    if current_superuser? && params[:account] then
      @acct.expires_at = params[:account][:expires_at] unless params[:account][:expires_at].blank?
      options = params[:account].keys.select {|k| k.ends_with?("_option")}
      options.each do |option|
        @acct.send("#{option}=", params[:account][option])
      end
    end

    if @acct.save then
      respond_to do |format|
        format.js { render :action => :update }
        format.html { redirect_to edit_account_path(@acct) }
      end
    else
      respond_to do |format|
        format.js do
          render :update => true do |page|
            page.alert @acct.errors.full_messages.join("\n")
          end
        end
        format.html { render :action => :edit }
      end
    end
  end

  def destroy
    flash_success "#{@acct.owner.display_name} account successfully destroyed" if @acct.destroy
    redirect_to accounts_path
  end
  
  def confirm
    return render(:text => "<p>Account cannot be activated without a confirmation token. Please follow the link in the confirmation email. </p>\
      <p>If you have registered more than 15 minutes ago, please verify your spam folder.</p>") if params[:code].blank?
    
    @acct = Account.find_by_confirmation_token(params[:code])
    
    return redirect_to(home_url) if @acct.blank?

    if Time.now > @acct.confirmation_token_expires_at then
      @acct.destroy
      return render(:text => "Confirmation token has already expired. Please register again")
    end

    @templates = @acct.available_templates
    @modules = @acct.available_modules
    @domain = @acct.domains.first
    @parent_domain = @domain.parent

    @owner = @acct.owner
    @address = AddressContactRoute.new
    @phone = PhoneContactRoute.new

    # Default value
    @acct.template_name = @acct.default_template
    @owner = @acct.owner
    
    @suite = nil
    @suite = AccountTemplate.find(params[:suite_id]) if params[:suite_id]
  end

  def activate
    @acct = Account.find_by_confirmation_token(params[:code])
    return redirect_to(home_url) if @acct.blank?

    if Time.now > @acct.confirmation_token_expires_at then
      @acct.destroy
      return render(:text => "Confirmation token has expired. Please register again")
    end

    @owner = @acct.owner
    params_avatar = params[:owner].delete(:avatar)
    @owner.attributes = params[:owner]
    
    @address = AddressContactRoute.new(params[:address])
    @phone = PhoneContactRoute.new(params[:phone])
    
    @domain = @acct.domains.first
    @parent_domain = @domain.parent
    
    begin
      Party.transaction do
        # make sure to confirm account owner otherwise they won't be able to login
        # the Party#authorize! will return immediately since the party does not have confirmation token
        @owner.confirm!
        
        @address.account = @phone.account = @acct
        @address.routable = @phone.routable = @owner
        @address.save!
        @phone.save! unless @phone.number.blank?
        
        # create a profile of the account owner
        @profile = @owner.profile
        unless @profile
          @profile = @owner.to_new_profile
          @profile.save!
          @owner.update_attribute(:profile_id, @profile.id)
          @owner.copy_contact_routes_to_profile!
        end
            
        # attach avatar to both profile and account owner party
        unless params_avatar.blank? || params_avatar.size == 0 then
          @profile.avatar.destroy if @profile.avatar
          avatar = @profile.build_avatar(:uploaded_data => params_avatar, :account => @profile.account)
          avatar.crop_resized("70x108")
          avatar.save!
          @profile.save!
          @owner.update_attribute(:avatar_id, avatar.id)
        else
          params[:owner].delete("avatar")
        end     
        
        # TODO: replace self.master_account with @acct.parent ?
        @order = @acct.generate_order_on!(self.master_account)

        if session[AFFILIATE_IDS_SESSION_KEY]
          @acct.affiliate_usernames = session[AFFILIATE_IDS_SESSION_KEY]
        end
        @acct.update_attributes!(params[:acct])
        
        @acct_template = nil
        if @acct.account_template_id
          @acct_template = AccountTemplate.find(@acct.account_template_id)
        else
          CopyAccountConfigurationsFuture.create!(:account => @acct, :owner => @acct.owner)
        end
        @account_template_future = @acct.create_account_module_subscription!(@acct_template, AccountModule.free_modules)
        
        @domain.domain_subscription = @acct.create_free_domain_subscription
        @domain.save!

        # Delay copying the template and modules to a later
        # date. This is an effort to prevent 502 Proxy Errors
        # during signup.
        
        @domain.activate!
        
        MethodCallbackFuture.create!(:account => @acct, :model => @acct, :method => "update_account_owner_info_in_master_account")
        
        affiliate_account = @owner.convert_to_affiliate_account!(@domain)
        if affiliate_account
          AffiliateAccountNotification.deliver_notification_from_account_signup(@domain, affiliate_account)
        end

        return redirect_to(:action => :index) if current_superuser?
    
        self.current_user = @owner
        if @order.blank? then
          @acct.activate!
          flash_success "Thank you for registering and welcome aboard!"
          if @acct_template
            render :template => "accounts/installing"
            return
          end
          redirect_to blank_landing_url
        else
          case params[:commit]
          when /paypal/i
            method = :paypal
          else
            flash_failure :now, "Unknown payment method, please choose PayPal"
            @templates = @acct.available_templates
            @modules = @acct.available_modules
      
            @owner.password = @owner.password_confirmation = nil
            render :action => "confirm"
            return
          end
    
          self.prepare_payment_and_redirect(
              :order => @order, :method => method,
              :amount => @order.total_amount,
              :description =>  @order.lines.first.description,
              :cancel_url => account_url(@acct))
        end      
      end
      
    rescue
      logger.warn {"==> Could not activate account #{@acct.id} #{@acct.domain_name}:\n#{$!.message}\n#{$!.backtrace.join("\n")}"}

      @templates = @acct.available_templates
      @modules = @acct.available_modules

      @owner.password = @owner.password_confirmation = nil
      
      @suite = nil
      @suite = AccountTemplate.find(params[:acct][:suite_id].to_i) if params[:acct] && params[:acct][:suite_id]
      
      render :action => "confirm"
    end
  end    

  def destroy_collection
    @destroyed_items_size = 0
    @undestroyed_items_size = 0
    Account.find(params[:ids].split(",").map(&:strip)).to_a.each do |account|
      if account.destroy
        @destroyed_items_size += 1
      else
        @undestroyed_items_size += 1
      end
    end
    
    error_message = []
    error_message << "#{@destroyed_items_size} account(s) successfully deleted" if @destroyed_items_size > 0
    error_message << "#{@undestroyed_items_size} account(s) failed to be destroyed" if @undestroyed_items_size > 0
    
    flash_success :now, error_message.join(", ") 
    respond_to do |format|
      format.js
    end
  end
  
  def resend_confirmation
    respond_to do |format|
      format.js do
        n=0
        Account.find(params[:ids].split(",").map(&:strip)).to_a.each do |account|
          if account.confirmation_token
            account.registering = true
            account.confirmation_url = lambda {|confirmation_token| confirm_accounts_url(:code => confirmation_token, :host => account.domains.first.name)}
            account.confirmation_token_expires_at = Configuration.get(:confirmation_token_duration_in_seconds).from_now
            account.save!
            n = n+1
          end
        end
        render :json => {:success => n!=0, :message => "Confirmation email has been resent to #{n} owners"}.to_json
      end
    end
  end
  
  protected
  def find_account
    @acct = Account.find(params[:id])
  end

  def protected?
    !%w(new create).include?(self.action_name)
  end

  def authorized?
    logger.debug {"\#authorized?  current_superuser? #{current_superuser?.inspect}"}
    return true if current_superuser?

    logger.debug {"\#authorized?  current_user? #{current_user?.inspect}\n\#authorized?  request.method: #{request.method.inspect}, self.action_name: #{self.action_name.inspect}"}
    return false unless current_user?

    (request.post? && self.action_name == "create") || (request.get? && self.action_name == "new")
  end

  def access_denied
    render :template => "shared/missing", :status => "404 Not Found", :layout => false
    return false
  end

  def choose_layout
    return "no-column" if %w(new).include?(self.action_name) && !current_user?
    return "plain-html" if %w(confirm activate create).include?(self.action_name)
    "two-columns"
  end
  
  def load_parent_domain
    @_parent_domain = self.get_request_parent_domain
  end
  
  def find_accounts
    search_options = {:offset => params[:start], :limit => params[:limit]}
    search_options.merge!(:order => "#{params[:sort]} #{params[:dir]}") if params[:sort]
    conditions_param = "party_id IS NOT NULL"
    if params[:level] && params[:level] !~ /all/i
      conditions_param += " AND id IN (?)"
      account_ids = Domain.find(:all, :select => "DISTINCT account_id", :conditions => {:level => params[:level].to_i}).map(&:account_id)
      conditions_param = [conditions_param, account_ids]
    end
    search_options.merge!(:conditions => conditions_param)
    
    query_params = params[:q]
    unless query_params.blank? 
      query_params = query_params.split(/\s+/)
      query_params = query_params.map {|q| q+"*"}.join(" ")
    end

    @accounts = Account.search(query_params, search_options)
    search_options.delete(:order)
    search_options.delete(:offset)
    search_options.delete(:limit)
    @accounts_count = Account.count_results(query_params, search_options)
  end
  
  def assemble_records(records)
    results = []
    records.each do |record|
      results << truncate_record(record)
    end
    results
  end
  
  def truncate_record(record)
    timestamp_format = "%d/%m/%Y"
    {
      :id => record.id,
      :object_id => record.dom_id, 
      :owner_name => record.owner.display_name,
      :owner_email => record.owner.main_email.email_address,
      :domain_names => record.domains.map(&:name).join(", "),
      :expires_at => record.expires_at.strftime(timestamp_format), 
      :amount => record.cost.to_s
    }
  end
end
