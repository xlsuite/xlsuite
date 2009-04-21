#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class SharedEmailAccountsController < ApplicationController
  required_permissions :none
  
  before_filter :load_email_account, :only => [:create, :remove, :remove_collection]

  def create
    @shared_email_account = SharedEmailAccount.new(:target_type => params[:target_type], :target_id => params[:target_id])
    @shared_email_account.email_account = @email_account
    @created = @shared_email_account.save
    errors = []
    unless @created
      errors = ["Sharing has already been setup"]
    end
    respond_to do |format|
      format.js do
        render(:json => {:success => @created, :errors => errors}.to_json)
      end
    end
  end

  def remove
    @removed = false
    @shared_email_account = SharedEmailAccount.first(:conditions => {:email_account_id => @email_account.id, 
      :target_id => params[:target_id], :target_type => params[:target_type]})
    if @shared_email_account
      @shared_email_account.destroy
      @removed = true
    end
    respond_to do |format|
      format.js do
        render(:json => {:success => @removed}.to_json)
      end
    end
  end
  
  def remove_collection
    target_ids = params[:target_ids].split(",").map(&:strip)
    @shared_email_accounts = SharedEmailAccount.all(:conditions => {:email_account_id => @email_account.id,
      :target_id => target_ids, :target_type => params[:target_type]})
    @shared_email_accounts.map(&:destroy)
    respond_to do |format|
      format.js do
        render(:json => {:success => true}.to_json)
      end
    end
  end

  def roles_tree
    respond_to do |format|
      format.json do
        if params[:email_account_id]
          self.load_email_account
          render(:json => build_role_collection_tree_panel_hashes.to_json)
        else
          render(:json => [].to_json)
        end
      end
    end
  end

  def parties
    if params[:email_account_id]
      self.load_email_account
      @shared_email_accounts = @email_account.shared_email_accounts.all(
        :select => "parties.id, parties.display_name",
        :joins => "INNER JOIN parties ON parties.id = target_id AND target_type='Party'",
        :conditions => {:target_type => "Party"})
      respond_to do |format|
        format.json do
          render(:json => {:collection => @shared_email_accounts, :total => @shared_email_accounts.size}.to_json)
        end
      end
    else
      respond_to do |format|
        format.json do
          render(:json => {:collection => [], :total => 0}.to_json)
        end
      end
    end
  end

  protected
  def load_email_account
    @email_account = self.current_account.email_accounts.find(params[:email_account_id])
  end

  def build_role_collection_tree_panel_hashes
    out = []
    object = @email_account
    root_roles = current_account.roles.find(:all, :conditions => "parent_id IS NULL", :order => "name")
    root_roles.each do |root_role|
      out << assemble_record_tree_panel_hash(root_role, object)
    end
    out
  end

  def assemble_record_tree_panel_hash(record, object=nil)
    hash = {:id => record.id, :text => record.name}
    if object
      hash.merge!(:checked => true) if @email_account.shared_email_accounts.first(:conditions => {:target_type => record.class.name, :target_id => record.id})
    end
    if record.children.count > 0
      children_hashes = []
      record.children.find(:all, :order => "name").each do |record_child|
        children_hashes << assemble_record_tree_panel_hash(record_child, object)
      end
      hash.merge!(:children => children_hashes)
    else
      hash.merge!(:leaf => true)
    end
    hash
  end

  def authorized?
    return true
  end
end
