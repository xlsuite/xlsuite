#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ListingsController < ApplicationController
  required_permissions :none
  before_filter :custom_required_permissions
  before_filter :load_listing, :only => %w(show edit update destroy images update_main_image multimedia other_files)
  before_filter :find_common_listing_tags, :only => %w(new edit)
  before_filter :parse_money, :only => %w(create update)

  def old
    @account_owner = current_account.owner
    @title = "Listings"

    items_per_page = params[:show] || ItemsPerPage
    items_per_page = current_account.listings.count if params[:show] =~ /all/i
    items_per_page = items_per_page.to_i

    @pager = ::Paginator.new(current_account.listings.count, items_per_page) do |offset, limit|
      current_account.listings.find(:all, :order => "updated_at DESC", :limit => limit, :offset => offset, :include => :address)
    end
    @page = @pager.page(params[:page])
    @listings = @page.items

    if params[:view] =~ /short/i
      render :action => 'index_short'
    else
      render :action => 'index_list'
    end
  end
  
  def async_destroy_collection
    destroyed_items_size = 0
    current_account.listings.find(params[:ids].split(",").map(&:strip)).to_a.each do |listing|
      destroyed_items_size += 1 if listing.destroy
    end

    render :json => {:success => (destroyed_items_size > 0), 
                     :message => "#{destroyed_items_size} listing(s) successfully deleted"}.to_json
  end
  
  def index
    respond_to do |format|
      format.html
      format.js
      format.json do
        find_listings
        records = assemble_records @listings
        wrapper = {'total' => @listings_count, 'collection' => records}
        render :json => wrapper.to_json
      end
    end
  end

  def new
    @listing = current_account.listings.build
    @address = @listing.build_address
    
    respond_to do |format|
      format.js
      format.html { return render_within_public_layout if params[:frontend]}
    end
  end

  def create
    Listing.transaction do
      @listing = current_account.listings.build
      @listing.attributes = params[:listing]
      @listing.current_domain = current_domain
      @address = @listing.build_address(params[:address])
      @listing.account = @address.account = current_account
      if @listing.save! and @address.save!
        @listing_created = true
        add_asset!(params[:asset])
        current_user.listings << @listing unless params[:not_creator_listing]
        flash_success :now, "Listing for #{@listing.address.line1} created"

        respond_to do |format|
          format.js
          format.html {redirect_to !params[:frontend].blank? ? ("/profiles/view?id=#{current_user.id}") : (listing_path(@listing))}
        end
      else
        flash_failure :now, @listing.errors.full_messages
        respond_to do |format|
          format.js 
          format.html {render :action => 'new'}
        end
      end
    end
  end

  def show
    return access_denied if !@listing.public? && !current_user?
    @account_owner = current_account.owner
    @title = @listing.quick_description
    render_using_public_layout
  end

  def edit
    @formatted_comments_path = formatted_comments_path(:commentable_type => "Listing", :commentable_id => @listing.id, :format => :json)
    @edit_comment_path = edit_comment_path(:commentable_type => "Listing", :commentable_id => @listing.id, :id => "__ID__")
    respond_to do |format|
      format.js 
      format.html do
        @address = @listing.address || @listing.build_address
      end
    end
  end
  
  def update
    Listing.transaction do
      #if status is changed to something else other than "sold", remove the "sold" tag
      if params[:listing] && params[:listing][:status] && !(params[:listing][:status].strip =~ /^sold$/i)
        @listing.tag_list = @listing.tag_list.gsub("sold", "") if @listing.tag_list.include?("sold")
      end
      
      if params[:listing]
        @listing.deactivate_commenting_on = nil if params[:listing][:deactivate_commenting_on] == "false"
        @listing.hide_comments = (params[:listing][:hide_comments]=="false") ? false : true unless params[:listing][:hide_comments].blank?
      
        @listing.update_attributes!(params[:listing])
      end
      @address = @listing.address || @listing.build_address
      @address.update_attributes!(params[:address]) if params[:address] 
      add_asset!(params[:asset]) if params[:asset]
      
      @listing_updated = true
      respond_to do |format|
        format.html {redirect_to listings_path}
        format.js do
          #@attribute = params[:listing].keys.first
        end
      end
    end

    rescue ActiveRecord::RecordInvalid
      @listing_updated = false
      respond_to do |format|
        format.html {render :action => :edit}
      end
  end

  def destroy
    if @listing.destroy
      respond_to do |format|
        format.html { redirect_to listings_path }
      end
    end
  end

  def async_tag_collection
    count = 0
    current_account.listings.find(params[:ids].split(",").map(&:strip)).to_a.each do |listing|
      listing.tag_list = listing.tag_list + " #{params[:tags]}"
      listing.save
      count += 1
    end
    flash_success :now, "#{count} listing(s) successfully tagged"
    render :update do |page|
      page << update_notices_using_ajax_response(:onroot => "parent")
    end
  end

  def async_mark_as_sold
    marked_size = 0
    current_account.listings.find(params[:ids].split(",").map(&:strip)).to_a.each do |listing|
      if params[:tag].blank? # tag listing with sold
        listing.status = "Sold"
        if current_account.owner.email_addresses.map(&:email_address).index(listing.contact_email) # owner of the listing is the account_owner
          listing.tag_list = "sold"
        else
          listing.tag_list = ""
        end
      else # change status to sold
        listing.tag_list = "sold"
      end
      marked_size += 1 if listing.save
    end
    if params[:tag].blank?
      flash_success :now, "#{marked_size} listing(s) status were changed to 'Sold'"
    else
      flash_success :now, "#{marked_size} listing(s) successfully tagged with sold"
    end
    @listing_updated = true if marked_size > 0
    render :update do |page|
      page << update_notices_using_ajax_response(:onroot => "parent")
    end
  end
  
  def auto_complete_party_field
    @parties = []
    
    unless params[:query].blank?
      @parties = current_account.parties.find(:all, :limit => 15, :conditions => [ 'LOWER(display_name) LIKE ?',
        '%' + params[:query].downcase + '%' ]).map{|p| [p.display_name + "   (" + (p.main_email.email_address ? p.main_email.email_address : "") + ")", p.display_name, p.id]}
    end
    respond_to do |format|
      format.json do
        render(:text => convert_to_auto_complete_json(@parties))
      end
    end
  end
  
  def auto_complete_remove_party_field
    @parties = []
    @listings = current_account.listings.find(params[:ids].split(",").map(&:strip))
    @listings.each do |listing|
      conditions = params[:query].blank? ? nil : [ 'LOWER(display_name) LIKE ?', '%' + params[:query].downcase + '%' ]
      @parties = @parties + listing.parties.find(:all, :conditions => conditions).map{|p| [p.display_name + "   (" + (p.main_email.email_address ? p.main_email.email_address : "") + ")", p.display_name, p.id]}
    end
    @parties.flatten.uniq!
    respond_to do |format|
      format.json do
        render(:text => convert_to_auto_complete_json(@parties))
      end
    end
  end
  
  def remove_listings_from_parties
    @parties = current_account.parties.find(params[:party_ids].split(",").map(&:strip)).to_a
    @listings = current_account.listings.find(params[:ids].split(",").map(&:strip))
    listings_remove_ids = params[:ids].split(",").map(&:strip)
    total = 0
    @parties.each do |party|
      start = party.listings.length
      party.interests.clear
      party.listings << party.listings.reject{|l| listings_remove_ids.include? l.id.to_s}
      total = start - party.reload.listings.length
    end
    parties_removed = @parties.length == 1 ? @parties.first.display_name : "#{@parties.length} parties"
    listings_removed = @parties.length == 1 ? total : @listings.length
    render :text => "#{listings_removed} listing(s) removed from #{parties_removed}"
  end
  
  def add_listings_to_parties
    @parties = current_account.parties.find(params[:party_ids].split(",").map(&:strip)).to_a
    @listings = current_account.listings.find(params[:ids].split(",").map(&:strip))
    listings = []
    @parties.each do |party|
      party_listings_ids = party.listings.map(&:id)
      listings = @listings.reject{|l| party_listings_ids.include? l.id}
      party.listings << listings
    end
    parties_added = @parties.length == 1 ? @parties.first.display_name : "#{@parties.length} parties"
    listings_added = @parties.length == 1 ? listings.length : @listings.length
    render :text => "#{listings_added} listing(s) added to #{parties_added}"
  end

  def import
    @title = 'Import MLS Listing'
    @listing = current_account.listings.find(:first, :conditions => {:mls_no => params[:mls_no]})
    raise ActiveRecord::RecordNotFound unless @listing

    @listing.publicify!
    redirect_to edit_listing_path(@listing)
  end

  def auto_complete_tag
    @q = params[:q]
    @tags = current_account.listings.tags_like(@q)

    render(:partial => "shared/auto_complete", :object => @tags)
  end

  def remove_duplicate_views
    current_account.listings.find(:all).each do |listing|
      listing.clean_duplicate_views
    end 
    redirect_to listings_path(params.reject {|key, value| key.to_s =~ /^controller|action$/})
  end
  
  def destroy_collection
    if current_account.listings.destroy(params[:listing_ids])
      flash_success "Listings successfully deleted"
    else
      flash_failure "Destroy listings failed"
    end
    redirect_to listings_path
  end
  
  def images
    @images = @listing.images
    respond_to do |format|
      format.js do
        render :json => assemble_images_to_json(@images, {:size => params[:size]})
      end
    end
  end
  alias_method :pictures, :images
  
  def multimedia
    @multimedia = @listing.multimedia
    respond_to do |format|
      format.js do
        render :json => assemble_images_to_json(@multimedia, {:size => params[:size]})
      end
    end
  end
  
  def other_files
    @other_files = @listing.other_files
    respond_to do |format|
      format.js do
        render :json => assemble_images_to_json(@other_files, {:size => params[:size]})
      end
    end
  end
  
  def main_image
    records = []
    
    if (@listing.main_image)
      asset = current_account.assets.find(@listing.main_image_id)
      records << {
        :id => asset.id,
        :url => download_asset_path(:id => asset.id),
        :filename => asset.filename
      }
    end
    
    respond_to do |format|
      format.js do
        wrapper = {:total => records.size, :collection => records}
        render :json => wrapper.to_json
      end
    end
  end
  
  def update_main_image
    @listing.main_image = params[:listing].delete(:main_image).to_i
    if @listing.save
      respond_to do |format|
        format.js do
          render :json => @listing.main_image_id.to_json
        end
      end
    else
    end
  end
  
  def upload_image
    Account.transaction do
      @picture = current_account.assets.build(:filename => params[:Filename], :uploaded_data => params[:file])
      @picture.content_type = params[:content_type] if params[:content_type]
      @picture.save!
      @view = @listing.views.create!(:asset_id => @picture.id, :classification => params[:classification])

      respond_to do |format|
        format.js do
          render :json => {:success => true, :message => 'Upload Successful!'}.to_json
        end
      end
    end

    rescue
      @messages = []
      @messages << @picture.errors.full_messages if @picture
      @messages << @view.errors.full_messages if @view
      logger.debug {"==> #{@messages.to_yaml}"}
      respond_to do |format|
        format.js do
          render :json => {:success => false, :error => @messages.flatten.delete_if(&:blank?).join(',')}.to_json
        end
      end
  end
  
  protected
  
  # Take the raw records and forge the appropriate ones
  def assemble_records(raw_records)
    records = []
    raw_records.each do |listing|
      record = {
        'id' => listing.id,
        'mls_no' => listing.mls_no,
        'address' => (listing.address ? listing.address.line1 : ""),
        'area' => listing.area,
        'city' => listing.city,
        'style' => listing.style,
        'no_bed_bath' => "#{listing.bedrooms}/#{listing.bathrooms}",
        'sqft' => listing.size,
        'price' => render_listing_price(listing.price),
        'description' => listing.description,
        'list_date' => listing.created_at.to_s,
        'last_transaction' => listing.updated_at.to_s,
        'status' => listing.status,
        'contact_email' => listing.contact_email,
        'dwelling_type' => listing.dwelling_type,
        'dwelling_class' => listing.dwelling_class,
        'title_of_land' => listing.title_of_land,
        'year_built' => listing.year_built,
        'num_of_images' => listing.num_of_images,
        'extras' => listing.extras.blank? ? "None" : listing.extras,
        'tags' => listing.tag_list,
        'picture_ids' => listing.pictures.collect { |picture| picture.id },
        'unapproved_comments' => listing.unapproved_comments_count
      }
      records.push record
    end
    
    return records
  end
  
  def find_listings
    search_options = {:offset => params[:start], :limit => params[:limit]}
    search_options.merge!(:order => "#{params[:sort]} #{params[:dir]}") if params[:sort]
    
    query_params = params[:q]
    unless query_params.blank? 
      query_params = query_params.split(/\s+/)
      query_params = query_params.map {|q| q+"*"}.join(" ")
    end

    @listings = current_account.listings.search(query_params, search_options)
    @listings_count = Listing.count_results(query_params, {:conditions => "listings.account_id = #{current_account.id} AND listings.type IS NULL"})
  end
  
  def load_listing 
    @listing = current_account.listings.find(params[:id])
  end

  def save_pictures
    remote_urls = params[:remote_urls].split
    remote_urls.each do |url|
      @listing.import_picture_from_uri!(url)
    end
  end

  def find_common_listing_tags
    @common_tags = current_account.listings.tags(:order => "count DESC, name ASC")
  end

  def parse_money
    return if params[:listing].blank?
    params[:listing].delete(:price) if params[:listing][:price] =~ /\A(free)?\Z/
    params[:listing][:price] = params[:listing][:price].gsub(",","").to_money if params[:listing].has_key?(:price)
  end

  def add_asset!(params)
    return if params.blank? || params[:uploaded_data].blank?
    params[:owner] = current_user
    params.delete(:filename) if params[:filename].blank?
    @asset = current_account.assets.create!(params)
    @listing.assets << @asset
  end
  
  def render_listing_price(money_object)
    price = money_object.format(:no_cents, :with_currency)
    # price should be in form [currency_sign]XXXXXX[currency_name] at this point
    num = price.slice!(/\d+/)
    return "No info" if num.nil?
    price[0..0] << num.reverse.scan(/\d{1,3}/).join(',').reverse << price[1..-1]
  end
  
  def custom_required_permissions
    has_required_permissions = if %w(async_destroy_collection new old create edit update destroy destroy_collection import auto_complete_tag remove_duplicate_views
                          async_mark_as_sold async_tag_collection auto_complete_remove_party_field remove_listings_from_parties).include?(params[:action].to_s)
      (current_user? && current_user.can?(:edit_listings))
    elsif %w(index add_listings_to_parties auto_complete_party_field).include?(params[:action].to_s)
      current_user?
    else %w(show).include?(params[:action].to_s) 
      true
    end
    has_required_permissions ? true : access_denied
  end
end
