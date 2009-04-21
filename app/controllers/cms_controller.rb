#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class CmsController < ApplicationController
  required_permissions %w(refresh_collection do_refresh_collection) => [:edit_layouts, :edit_pages, :edit_snippets], 
      %w(create_listings_website_templates_chooser create_listings_website \\
        do_create_listings_website create_website_success save_google_map_api) => [:edit_listings]
  
  def refresh_collection
    @template_domain_selections = []
    current_account.available_templates.map(&:name).each do |domain_name|
      @template_domain_selections << [domain_name]
    end
    respond_to do |format|
      format.js
    end
  end
  
  def do_refresh_collection
    @domain = Domain.find_by_name(params[:domain_name])
    ActiveRecord::Base.transaction do
      %w(layouts pages snippets).each do |type|
        instance_variable_set("@#{type}_replaced".to_sym, false)
        if params[("include_" + type).to_sym]
          current_account.send(type).map(&:destroy)
          current_account.send(["copy", type, "from!"].join("_"), @domain)
          instance_variable_set("@#{type}_replaced".to_sym, true)
        end
      end
      respond_to do |format|
        format.js
      end
    end
  end
  
  def create_listings_website_templates_chooser
    @template_domain_selections = []
    current_account.available_house_templates.map(&:name).each do |domain_name|
      @template_domain_selections << [domain_name]
    end
    @template_domain_selections = [[]] if @template_domain_selections.blank?
    respond_to do |format|
      format.js
    end
  end
  
  def create_listings_website
    @listings = current_account.listings.find(params[:ids].split(',')).to_a
    @_template = Domain.find_by_name(params[:domain_name])
    @account_title = @listings.first.address.line1.downcase.gsub(/#/, "").strip.gsub(/\s/, "_") + "." + current_domain.name.gsub(/^www\./, "")
  end
  
  def do_create_listings_website
    @_template = Domain.find(params[:domain_id])
    ActiveRecord::Base.transaction do
      @account = Account.new(:title => params[:account_title])
      @account.expires_at = 1.years.from_now
      @account.save!
      @account.configurations.find_by_name("login_redirection").update_attribute("str_value", "/admin")
      
      if !params[:contact_id].blank?
        @old_party = current_account.parties.find(params[:contact_id])
  
        @new_party = Party.new()
        # update the party in the current account, and copy his info to the new account
        @old_party.copy_to_account(@new_party, @account)
        @old_party.tag_list = @old_party.tag_list << ", mini-site, #{@account.title}"
        @old_party.links.create!(:name => "Mini-site", :url => @account.title)
        @old_party.save!
        @new_party.tag_list = @new_party.tag_list << " , account-owner"
        @new_party.save!
  
        @new_party.append_permissions(Permission.find(:all).map(&:name).map(&:to_sym))
        @new_party.reload
      end
      
      @domain = Domain.create!(:name => params[:account_title], :account => @account, :role => "browsing")
      
      # Copy current user and current account's user to new account's contact list
      [current_user, current_account.owner].each do |party|
        next if Party.find_by_account_and_email_address(@account, party.main_email.email_address)
        new_party = Party.new()
        party.copy_to_account(new_party, @account)
        new_party.append_permissions(Permission.find(:all).map(&:name).map(&:to_sym))
        new_party.tag_list = ""
        new_party.save!
        # Assign current account's owner as new account's owner
        @account.owner = new_party if party.id == current_account.owner.id
      end
      @account.save!
      
      # Copy layouts, pages, and snippets to new account
      %w(layouts pages snippets).each do |type|
        @account.send(["copy", type, "from!"].join("_"), @_template)
      end
      
      # Copy listings
      @listings = current_account.listings.find(params[:listing_ids].split(',')).to_a
      @listings.each do |listing|
        @new_listing = Listing.new(:account_id => @account.id)
        listing.copy_to(@new_listing)
        @new_listing.account_id = @account.id
        @new_listing.price = listing.price
        @new_listing.external_id = listing.external_id
        @new_listing.save!
        listing.assets.each do |asset|
          @new_asset = @account.assets.create!(:temp_data => asset.send(:current_data), 
              :filename => asset.filename, :content_type => asset.content_type, :size => asset.size, :tag_list => asset.tag_list,
              :width => asset.width, :height => asset.height, :title => asset.title, :description => asset.description)
          @new_listing.assets << @new_asset
          View.find_by_asset_id(@new_asset.id).update_attribute("classification", listing.views.find_by_asset_id(asset.id).classification)
          View.find_by_asset_id(@new_asset.id).update_attribute("position", listing.views.find_by_asset_id(asset.id).position)
          asset.thumbnails.each do |thumb|
            new_thumb = @account.assets.create!(:temp_data => thumb.send(:current_data), :parent_id => @new_asset.id,
              :filename => thumb.filename, :content_type => thumb.content_type, :size => thumb.size, :tag_list => thumb.tag_list,
              :width => thumb.width, :height => thumb.height, :title => thumb.title, :description => thumb.description)
          end
        end
      end
      @success = true
    end
    if @success && @new_party
      if params[:reset] =~ /true/i
        @new_party.reset_password(params[:account_title])
      end
    end
    @google_maps = @account.snippets.find_by_title('google_api_key')
    respond_to do |format|
      format.js do
        if @google_maps
          render :json => {:success => true, :google_maps => true, :account_title => @account.title, :account_id => @account.id}.to_json
        else
          render :json => {:account_title => @account.title, :success => true, 
                 :message => "Account #{@account.title} created! You and this account's owner is added to the new account's contact list."}.to_json
        end
      end
    end
    rescue
      respond_to do |format|      
        format.js  do
          render :json => {:error => "Creation of #{@account.title} failed. Reason: #{$!.message}"}.to_json
        end
      end
  end
  
  def save_google_map_api
    Account.find(params[:account_id]).snippets.find_by_title('google_api_key').update_attribute('body', params[:api_key])
    respond_to do |format|      
      format.js  do
        render :json => {:success => true}.to_json
      end
    end
  end
  
  def create_website_success
    @title = params[:title]
    @api_msg = params[:api_msg]
    respond_to do |format|
      format.js
    end 
  end
end
