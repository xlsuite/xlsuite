#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class DomainsController < ApplicationController
  required_permissions :none # Check #authorized? implementation below
  before_filter :load_domain_account
  before_filter :load_domain, :only => %w(edit update destroy bypass)

  helper AccountsHelper

  def index
    limit = Integer(params[:show] || 30) rescue 30

    conds = {}
    @role = params[:role]
    conds[:conditions] = ["role = ?", @role.downcase] unless @role.blank?

    @paginator = ::Paginator.new(@acct.domains.count(:all, conds), limit) do |offset|
      @acct.domains.find(:all, conds.merge(:order => "name", :offset => offset, :limit => limit))
    end

    @page = @paginator.page(params[:page])
    @domains = @page.items
    @domain_subscriptions = current_account.domain_subscriptions
  end

  def new
    @domain = @acct.domains.build
    @domain_subscription_products_map = @acct.find_next_available_domain_subscription_products
    @domain_subscription_with_empty_slot = @acct.find_domain_subscription_with_empty_slot
  end

  def create
    ActiveRecord::Base.transaction do
      preview_thumbnail = params[:domain].delete("picture")
      @domain = @acct.domains.create!(params[:domain])
      if !preview_thumbnail.blank? then
        asset = current_account.assets.build(:uploaded_data => preview_thumbnail) 
        asset.owner = current_user
        asset.tag_list = "#{@domain.name}, thumbnail"
        asset.save!
      end
      @domain_subscription = current_account.find_or_create_domain_subscription(params[:level])
      @domain.domain_subscription = @domain_subscription
      @domain.save!
    end

    respond_to do |format|
      format.html do
        redirect_to(super_with_account? ? edit_account_path(@acct) : domains_path)
      end
      format.js
    end

  rescue ActiveRecord::RecordInvalid
    @domain = $!.record
    @domain_subscription_products_map = @acct.find_next_available_domain_subscription_products
    @domain_subscription_with_empty_slot = @acct.find_domain_subscription_with_empty_slot
    render :action => :new
  end

  def edit
    render
  end

  def update
    Domain.transaction do
      preview_thumbnail = params[:domain].delete("picture")
      thumbnails = @domain.find_thumbnails
      old_name = @domain.name
      @domain.update_attributes!(params[:domain])
      if !preview_thumbnail.blank?
        asset = current_account.assets.build(:uploaded_data => preview_thumbnail) 
        asset.owner = current_user
        asset.tag_list = "#{@domain.name}, thumbnail"
        asset.save!
      elsif !thumbnails.blank?
        thumbnails.first.tag_list = thumbnails.first.tag_list.gsub(old_name, @domain.name)
        thumbnails.first.save!
      end
    end
    respond_to do |format|
      format.html do
        redirect_to(super_with_account? ? edit_account_path(@acct) : domains_path)
      end
      format.js
    end

  rescue ActiveRecord::RecordInvalid
    @domain = $!.record
    render :action => :edit
  end

  def destroy
    @domain.destroy
    respond_to do |format|
      format.html do
        redirect_to(super_with_account? ? edit_account_path(@acct) : domains_path)
      end
      format.js do
        render :update => true, :layout => false, :type => "text/javascript; charset=UTF-8" do |page|
          page.visual_effect :fade, dom_id(@domain)
          page.delay(2) do
            page.remove dom_id(@domain)
          end
        end
      end
    end
  end
  
  def validate_name
    respond_to do |format|
      format.js do
        d = current_account.domains.build(:name => params[:name])
        json_response = nil
        if Domain.find_by_name(params[:name]) && d.valid?
          json_response = {:valid => false, :errors => "Sorry, name is already taken"}.to_json
        else
          json_response = {:valid => d.valid?, :errors => d.errors.full_messages.join(",")}.to_json
        end
        if params[:callback]
          return render(:json => "#{params[:callback]}(#{json_response})")
        else
          return render(:json => json_response)
        end
      end
    end
  end
  
  def bypass
    @domain.bypass!
    respond_to do |format|
      format.js do
        render :update => true, :layout => false, :type => "text/javascript; charset=UTF-8" do |page|
          page.visual_effect :highlight, dom_id(@domain)
          page.delay(1) do
            page.replace(dom_id(@domain), :partial => "accounts/domain", :locals => {:domain => @domain})
          end
        end
      end
    end
  end

  protected
  def authorized?
    if self.action_name !~ /bypass/i
      return true if params[:action].to_s =~ /validate_name/i
      return true if current_superuser?
      return true if current_account.owner == current_user
      current_user.can?(:edit_domains)
    else
      self.current_superuser?
    end
  end

  def access_denied
    render :unauthorized
    return false
  end

  def load_domain_account
    @acct = if super_with_account? then
              Account.find(params[:account_id])
            else
              current_account
            end
  end

  def load_domain
    @domain = @acct.domains.find(params[:id])
  end

  def super_with_account?
    current_superuser? && !params[:account_id].blank?
  end
end
