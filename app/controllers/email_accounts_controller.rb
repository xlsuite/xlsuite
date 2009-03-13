#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class EmailAccountsController < ApplicationController
  helper :tabs, :contact_routes, :parties

  layout "parties-two-columns"
  
  required_permissions %w(index new create edit update destroy retrieve retrieve_all) => [:edit_party, :edit_own_account, {:any => true}]
  
  before_filter :load_party
  before_filter :load_party_email_addresses
  before_filter :check_own_access
  before_filter :load_groups
  before_filter :set_page_title
  
  def index
    %w(address phone link email).each do |attr|
      instance_variable_set("@new_#{attr}_url", send("new_party_#{attr}_path", @party))
    end
    
    @email_accounts = @party.email_accounts
    @email_addresses = @party.email_addresses.find(:all, :order => "email_address ASC")
    respond_to do |format|
      format.html
      format.js { render :layout => false }
    end
  end
  
  def new
    @email_account = EmailAccount.new
  end

  def create
    @email_account = @party.email_accounts.build(params[:email_account])
    if save_and_navigate
      flash_success "New email account successfully created"
      respond_to do |format|
        format.html {redirect_to party_email_accounts_path(@party)}
        format.js
      end
    else
      @email_accounts = @party.email_accounts(true)
      @email_addresses = @party.email_addresses.find(:all, :order => "email_address ASC")
      render :action => "index"
    end
  end
  
  def edit
    @email_account = @party.email_accounts.find(params[:id])
  end
  
  def update
    @email_account = @party.email_accounts.find(params[:id])
    if save_and_navigate
      flash_success "Email account successfully updated"
      redirect_to party_email_accounts_path(@party)
    else
      render :action => "edit"
    end
  end

  def destroy
    email_account = @party.email_accounts.find(params[:id])
    if email_account.destroy
      flash_success "Email account successfully destroyed"
    end
    redirect_to party_email_accounts_path(@party)
  end
  
  def retrieve
    @email_account = current_user.email_accounts.find(params[:id])
    begin
      @email_account.retrieve!(1)
      flash_success "Retrieved successfully"
      return redirect_to(:back) if request.env["HTTP_REFERER"]
      render :update do |page|
        page << "parent.$('status-bar-notifications').innerHTML = #{render_plain_flash_messages}"
        page << "parent.unreadMailRefresh()"
      end
    rescue
      flash_failure "Error in connecting to #{@email_account.server}. Please check email account data you inputted"
      return redirect_to(:back) if request.env["HTTP_REFERER"]
      redirect_to party_email_accounts_path(@party)
    end
  end
  
  def retrieve_all
    email_accounts = current_user.email_accounts.find(:all)
    email_accounts.each {|e| e.retrieve! rescue flash_failure "Error in connecting to #{e.server}. Please check email account data you inputted"}
    redirect_to show_unread_emails_emails_path
  end
  
  protected
  def save_and_navigate
    EmailAccount.transaction do
      case params[:email_account][:access_method]
      when 'POP3'
        case @email_account
        when Pop3EmailAccount
          # NOP, we keep the same type
        else
          account = @email_account
          @email_account = Pop3EmailAccount.new(params[:email_account])
          @email_account.account_id = current_account.id
          @email_account.attributes = account.attributes
          account.destroy
        end
      when 'IMAP'
        flash_failure :now, "IMAP server not coded at present"
      else
        flash_failure :now, "Unknown server access method"
      end
    end

    @email_account.attributes = params[:email_account]
    @email_account.account = current_account
    @email_account.error_message = nil
    @email_account.failures = 0
    @email_account.save
  end

  def load_party
    @party = current_account.parties.find(params[:party_id])
  end
  
  def load_party_email_addresses
    @email_addresses = @party.email_addresses.find(:all, :order => 'email_address ASC')
  end
   
  def check_own_access
    return if current_user.can?(:edit_party)
    return access_denied unless @party == current_user
  end

  def load_groups
    @groups = current_account.groups.find(:all, :order => "name")
  end
  
  def set_page_title
    @title = [@party.name.to_s, "Email Accounts"].join(" | ")
    #@title = [action_name == "general" ? nil : action_name.humanize.capitalize, @party.name.to_s].compact.join(" | ")
  end
end
