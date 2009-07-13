#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Public::ListingsController < ApplicationController
  required_permissions :none
  before_filter :filter_params
  before_filter :load_profile, :only => %w(create update)
  before_filter :custom_required_permissions
  before_filter :load_listing, :only => %w(update destroy embed_code)
  before_filter :parse_money, :only => %w(create update)
  
  def create
    begin
      Listing.transaction do
        @listing = current_account.listings.build
        @listing.attributes = params[:listing]
        @listing.current_domain = current_domain
        @listing.creator = @profile ? @profile.party : current_user
        @address = @listing.build_address(params[:address])
        @listing.account = @address.account = current_account
        @listing.save!
        @address.save!
        add_asset!(params[:asset]) unless params[:asset].blank?
        flash_success "Listing for #{@listing.address.line1} created"
        params[:next]=params[:next].gsub(/__id__/i, @listing.id.to_s).gsub(/__quick_description__/i, @listing.quick_description)\
            .gsub(/__gmap_query__/i, @listing.gmap_query).gsub(/__mls_no__/i, @listing.mls_no || "") if params[:next]
        respond_to do |format|
          format.html do
            redirect_to_next_or_back_or_home
          end
        end
      end
    rescue
      raise
      errors = $!.message.to_s
      respond_to do |format|
        format.html do
          flash_failure errors
          return redirect_to_return_to_or_back_or_home
        end
        format.js do
          render :json => {:success => false, :errors => [errors]}
        end
      end
    end
  end
  
  def update
    Listing.transaction do      
      begin
        if params[:listing]
          @listing.deactivate_commenting_on = nil unless params[:listing][:deactivate_commenting_on]
          @listing.hide_comments = nil unless params[:listing][:hide_comments]
          @listing.update_attributes!(params[:listing])
        end
        @address = @listing.address || @listing.build_address
        @address.update_attributes!(params[:address]) if params[:address] 
        add_asset!(params[:asset]) if params[:asset]
        
        params[:next]=params[:next].gsub(/__id__/i, @listing.id.to_s).gsub(/__quick_description__/i, @listing.quick_description)\
            .gsub(/__gmap_query__/i, @listing.gmap_query).gsub(/__mls_no__/i, @listing.mls_no || "") if params[:next]
        respond_to do |format|
          format.html do
            flash_success params[:success_message] || "Listing #{@listing.address.line1} successfully updated"
            return redirect_to_next_or_back_or_home
          end
          format.js do
            render :json => {:success => true}
          end
        end
      rescue
        errors = $!.message.to_s
        respond_to do |format|
          format.html do
            flash_failure errors
            return redirect_to_return_to_or_back_or_home
          end
          format.js do
            render :json => {:success => false, :errors => [errors]}
          end
        end
      end
    end
  end
  
  def destroy
    @destroyed = @listing.destroy
    if @destroyed
      flash_success params[:success_message] || "Listing #{@listing.address.line1} successfully destroyed"
    else
      errors = $!.message.to_s
      flash_failure errors
    end
    respond_to do |format|
      format.html do
        return @destroyed ? redirect_to_next_or_back_or_home : redirect_to_return_to_or_back_or_home
      end
      format.js do
        render :json => {:success => true, :errors => [errors]}
      end
    end
  end

  def embed_code
    success = true
    errors = []
    @profile = nil
    if params[:profile_id] && !params[:profile_id].blank?
      @profile = self.current_account.profiles.find(params[:profile_id])
    else
      @profile = nil
    end
    if @profile
      @profile = @profile.to_liquid
    end
    snippet = self.current_account.snippets.find_by_title(self.current_domain.get_config("listing_embed_code_snippet"))
    if success && snippet
      affiliate_username = self.current_user? ? self.current_user.affiliate_username : ""
      liquid_assigns = {"account" => self.current_account.to_liquid, "user" => PartyDrop.new(self.current_user), "logged_in" => self.current_user?,
        "listing" => @listing.to_liquid, "profile" => @profile, "domain" => self.current_domain.to_liquid,
        "user_affiliate_username" => affiliate_username, "user_affiliate_id" => affiliate_username}
      registers = {"account" => self.current_account, "domain" => self.current_domain}
      liquid_context = Liquid::Context.new(liquid_assigns, registers, false)
      @text = Liquid::Template.parse(snippet.body).render!(liquid_context)
    else
      success = false
      errors << "Listing embed code snippet cannot be found"
    end
    respond_to do |format|
      format.js do
        render(:json => {:success => success, :errors => errors, :title => @listing.quick_description, :text => @text}.to_json)
      end
    end
  end
  
  protected
  def load_listing 
    @listing = current_account.listings.find(params[:id])
  end

  def parse_money
    return if params[:listing].blank?
    params[:listing].delete(:price) if params[:listing][:price] =~ /\A(free)?\Z/
    params[:listing][:price] = params[:listing][:price].gsub(",","").to_money if params[:listing].has_key?(:price)
  end

  def add_asset!(params)
    return if params.blank?
    @asset = current_account.assets.create!(:uploaded_data => params)
    @listing.assets << @asset
  end
  
  def custom_required_permissions
    return true if %w(embed_code).include?(params[:action].to_s)
    has_required_permissions = if !current_user? 
      false
    elsif current_user.can?(:edit_listings)
      true
    elsif params[:action] =~ /create/i
      @profile ? @profile.writeable_by?(current_user) : true
    elsif params[:action] =~ /(update|destroy)/i
      self.load_listing
      (@listing.creator && @listing.creator.id == current_user.id) || 
        (@listing.creator.profile && @listing.creator.profile.writeable_by?(current_user))
    elsif %w(show).include?(params[:action].to_s) 
      true
    end
    has_required_permissions ? true : access_denied
  end
  
  def load_profile
    if params[:profile_id] && !params[:profile_id].blank?
      @profile = current_account.profiles.find(params[:profile_id])
    end
  end
  
  def filter_params
    params.delete(:tag_list)
    true
  end
end
