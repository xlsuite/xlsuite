#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class EmailAccountsController < ApplicationController
  required_permissions %w(create update test) => [:edit_party, :edit_own_account, {:any => true}]
  
  before_filter :load_party
  before_filter :load_email_account, :only => [:update, :test]
    
  def create
    klass = case params[:type]
      when /^imap$/i
        params[:email_account][:type] = ImapEmailAccount
      when /^smtp$/i
        params[:email_account][:type] = SmtpEmailAccount
      else
        raise StandardError, "Type not supported"
      end
    @email_account = klass.new(params[:email_account])
    @email_account.party = @party
    @email_account.account = self.current_account
    @created = @email_account.save
    respond_to do |format|
      format.js do
        if @created
          render(:json => {:id => @email_account.id, :success => true, :messages => [params[:type].upcase + " account successfully created"]}.to_json)
        else
          render(:json => {:success => false, :errors => @email_account.errors.full_messages}.to_json)
        end
      end
    end
  end
    
  def update
    @email_account.attributes = params[:email_account]
    if params[:type]
      @email_account.type = case params[:type]
      when /^imap$/i
        ImapEmailAccount.name
      when /^smtp$/i
        SmtpEmailAccount.name
      else
        raise StandardError, "Type not supported"
      end
    end
    @updated = @email_account.save
    respond_to do |format|
      format.js do
        if @updated
          render(:json => {:id => @email_account.id, :success => true, :messages => [params[:type].upcase + " account successfully updated"]}.to_json)
        else
          render(:json => {:id => @email_account.id, :success => false, :errors => @email_account.errors.full_messages}.to_json)
        end
      end
    end
  end
  
  def test
    @success, messages = @email_account.test
    respond_to do |format|
      format.js do
        response_hash = {:success => @success}
        unless @success
          response_hash.merge!(:error => messages)
        end
        render(:json => response_hash.to_json)
      end
    end
  end
  
  protected
  def load_email_account
    @email_account = EmailAccount.first(:conditions => {:account_id => self.current_account.id, :id => params[:id]})
  end
  
  def load_party
    @party = self.current_account.parties.find(params[:party_id])
  end
end
