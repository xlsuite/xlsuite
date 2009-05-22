#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class RetsController < ApplicationController
  before_filter :check_account_authorization # Must go before required_permissions so account authorizations take precedence over permissions
  required_permissions :access_rets
  before_filter :load_operators, :only => %w(search)
  before_filter :load_common_tags, :only => %w(search listings_search edit_listings_search)

  def index
    respond_to do |format|
      format.js
      format.json do
    
        @rets_search_futures = RetsSearchFuture.all(:conditions => "account_id = #{current_account.id} AND `interval` IS NOT NULL", 
                                                    :order => "scheduled_at DESC")
        render :json => {:collection => assemble_rets(@rets_search_futures), :total => @rets_search_futures.size}.to_json
      end
    end
  end
  
  def edit_listings_search
    @rets_search_future = RetsSearchFuture.first(:conditions => ["account_id = #{current_account.id} AND id=?", params[:id]])
    @search = (params[:search] || {}).symbolize_keys.reverse_merge(:resource => "Property", :class => "11", :limit => 5)
    find_default_resource_class_fields
    
    @mls_number_field     = lookup_field(@fields, "MLS Number")
    @list_date_field      = lookup_field(@fields, "List Date")
    @street_address_field = lookup_field(@fields, "Address")
    @postal_code_field    = lookup_field(@fields, "Postal Code")
    @list_price_field     = lookup_field(@fields, "List Price")

    @status_field         = lookup_field(@fields, "Status")
    @status               = lookup_values(@search[:resource], @status_field)

    @city_field           = lookup_field(@fields, "City")
    @cities               = lookup_values(@search[:resource], @city_field)

    @area_field           = lookup_field(@fields, "Area")
    @areas                = lookup_values(@search[:resource], @area_field)

    @dwelling_style_field = lookup_field(@fields, "Style of Home")
    @dwelling_styles      = lookup_values(@search[:resource], @dwelling_style_field)

    @dwelling_type_field  = lookup_field(@fields, "Type of Dwelling")
    @dwelling_types       = lookup_values(@search[:resource], @dwelling_type_field)

    @dwelling_class_field = lookup_field(@fields, "Dwelling Classification")
    @dwelling_classes     = lookup_values(@search[:resource], @dwelling_class_field)

    @title_of_land_field  = lookup_field(@fields, "Title to Land")
    @title_of_lands       = lookup_values(@search[:resource], @title_of_land_field)

    @bedrooms_field       = lookup_field(@fields, "Total Bedrooms")
    @bathrooms_field      = lookup_field(@fields, "Total Baths")

    delete_default_fields

    respond_to do |format|
      format.js
      format.html
    end
    
  end
  
  def update_listings_search
    @future = RetsSearchFuture.first(:conditions => ["account_id = #{current_account.id} AND id=?", params[:id]])
    
    if !params[:area_points].blank? && params[:search_using] == "Google Map" then
      polygon = Polygon.new(:points => params[:area_points])
      params[:line]["7"][:operator] = "eq"
      params[:line]["7"][:from]     = polygon.to_geocodes.map(&:zip).map {|zip| "%s %s" % [zip.first(3), zip.last(3)]}.join(",")
      # Even though RETS returns postal codes without spaces, we have
      # to query *with* the space, or else the query will return bogus results
    end

    line_params = params[:line].clone
    line_params["1"]["from"].upcase!
    line_params.delete_if { |key,value| value["from"].blank? && value["to"].blank? }
    
    @future.args = {
      :search   => (params[:search] || {}).symbolize_keys,
      :lines    => (line_params || {}).values.map(&:symbolize_keys),
      :polygon  => params[:area_points]
    }
    @future.interval = Period.parse(params[:search][:repeat_interval]).as_seconds if params[:search] && !params[:search][:repeat_interval].blank?
    @future.save!
    
    flash_success "Saved search updated."
    
    respond_to do |format|
      format.js
      format.html
    end
  end
  
  def suspend_collection
    count = RetsSearchFuture.update_all("status='suspended'", ["account_id = ? AND id in (?) ", current_account.id, params[:ids].split(",").map(&:strip).map(&:to_i)])
    flash_success "#{count} saved searches suspended."
    respond_to do |format|
      format.js do
        render :template => "rets/destroy_collection"
      end
    end
  end
  
  def resume_collection
    futures = RetsSearchFuture.all(:conditions => ["account_id = ? AND id in (?) ", current_account.id, params[:ids].split(",").map(&:strip).map(&:to_i)]).to_a
    futures.each do |future|
      future.reschedule!(Time.now)
    end
    
    flash_success "#{futures.size} saved searches resumed."
    respond_to do |format|
      format.js do
        render :template => "rets/destroy_collection"
      end
    end
  end
  
  def destroy_collection
    @destroyed_items_size = 0
    @undestroyed_items_size = 0
    RetsSearchFuture.all(:conditions => ["account_id = ? AND id in (?) ", current_account.id, params[:ids].split(",").map(&:strip).map(&:to_i)]).to_a.each do |future|
      if future.destroy
        @destroyed_items_size += 1
      else
        @undestroyed_items_size += 1
      end
    end

    error_message = []
    error_message << "#{@destroyed_items_size} saved searches successfully deleted" if @destroyed_items_size > 0
    error_message << "#{@undestroyed_items_size} saved searches failed to be destroyed" if @undestroyed_items_size > 0

    flash_success :now, error_message.join(", ")
    respond_to do |format|
      format.js
    end
  end

  def search
    @search = (params[:search] || {}).symbolize_keys.reverse_merge(:resource => "Property", :class => "11", :limit => 5)
    find_default_resource_class_fields
  end

  def do_search
    @future = RetsSearchFuture.new(:owner => current_user, :account => current_account,
        :args => {:search => (params[:search] || {}).symbolize_keys,
                  :lines => (params[:line] || {}).values.map(&:symbolize_keys)
        }, :result_url => results_rets_path(:id => "_id_"))
    @future.save!
    redirect_to future_path(@future)

    rescue
      logger.warn $!
      logger.warn $!.backtrace.join("\n")
      flash_failure @future.errors.full_messages.join("; ")

      redirect_to :action => :search
  end

  def classes
    @classes = RetsMetadata.find_all_classes(params[:resource])
    render :inline => "<%= options_for_select(@classes) %>", :layout => false
  end

  def fields
    @fields = RetsMetadata.find_all_fields(params[:resource], params[:class])
    render :inline => %Q(<%= render :partial => "field", :collection => @fields %>), :layout => false
  end

  def lookup
    @values = RetsMetadata.find_lookup_values(params[:resource], params[:id])
    @name = params[:name].blank? ? :value_from : params[:name]
    render :layout => false
  rescue ActiveRecord::RecordNotFound, ArgumentError
      @name = params[:name].blank? ? :value_from : params[:name]
      render :inline => "<%= text_field_tag @name, '', :class => 'text' %>", :layout => false
  end

  def results
    @ids = params[:ids]
    @id = params[:id]
    @futures = current_account.futures.find(params[:ids].map(&:strip), :order => "ended_at") if params[:ids]
    @future = current_account.futures.find(params[:id]) if params[:id]
    
    listings_results = []
    listings_results += @future.results[:listings].map if @future
    @futures.each do |future|
      listings_results << future.results[:listings]
    end if @futures
    
    listings_results.compact!
    listings_results.flatten!
    listings_results.uniq!
    
    if listings_results.blank?
      flash.discard
      flash_failure "No listing found"
      return redirect_to(listings_url)
    end
    
    @listings = listings_results.map do |row|
      current_account.listings.find(row[:id])
    end
    
    respond_to do |format|
      format.html
      format.js
      format.json do        
        records = assemble_records @listings
        wrapper = {'total' => @listings.size, 'collection' => records}
        render :json => wrapper.to_json
      end
    end
  end

  def import
  end

  def do_import
    @future = current_account.futures.find(params[:id])
    @listing = @future.results[:properties].select do |property|
      listing = current_account.listings.find_or_initialize_by_property(@future.args[:search][:resource],
          @future.args[:search][:class], property, :account => current_account)
      listing.id == params[:external_id]
    end

    return(render(:missing)) unless @listing
    @listing.save!
  end

  def done
  end

  def get_photos
    @id = (params[:id] || "").scan(/\d+/).first
    @future = RetsPhotoRetriever.create!(:account => current_account, :owner => current_user,
        :args => {:key => params[:id], :tags => "listing #{params[:mls_no]} #{params[:region]}"})
    respond_to do |format|
      format.html do
        @future.update_attribute(:result_url, results_rets_url(:id => "_id_"))
        redirect_to(@future)
      end
      format.js
    end
  end

  def refresh_photos
    @future = current_account.futures.find(params[:id])
    @photos = @future.photos
    @root = params[:root]
    @id = @root.scan(/\d+/).first
  end

  def listings_import
    @search = (params[:search] || {}).symbolize_keys.reverse_merge(:resource => "Property", :class => "11", :limit => 5)
    find_default_resource_class_fields
    @mls_number_field = @fields.detect {|e| e.description == "MLS Number"}
    @address_field = @fields.detect {|e| e.description == "Address"}
    
    respond_to do |format|
      format.js
      format.html
    end
  end

  def do_listings_import
    future_ids = []

    params[:searches].each_pair do |key, search_param| 
      line_params = search_param[:line]
      line_params["1"]["from"].upcase! # capitalize mls_number input
      line_params["1"]["from"] = line_params["1"]["from"].gsub(/\s+/, "").split(",").reject(&:blank?)
      mls_nos_count = line_params["1"]["from"].size
      line_params["1"]["from"] = line_params["1"]["from"].join(",")
      
      line_params.delete_if { |line_param_key, line_param_value| line_param_value["from"].blank? && line_param_value["to"].blank? }
      next if line_params.blank?
      
      future = RetsSearchFuture.create!(:owner => current_user, :account => current_account,
          :args => {:search => (search_param[:search].merge(params[:search]).merge(:limit => mls_nos_count) || {}).symbolize_keys,
                    :lines => (search_param[:line] || {}).values.map(&:symbolize_keys),
                    :recipients => params[:recipient][key].values.reject(&:blank?)},
                    :result_url => results_rets_path(:id => "_id_"))
      future_ids << future.id
    end

    ListingRecipientsMailSender.create!(:owner => current_user, :account => current_account,
      :args => {:future_ids => future_ids, :listing_url => listing_url(:id => "__id__"), 
      :forgot_password_url => forgot_password_parties_url} )
    
    #ListingNewsletterMailSender.create!(:owner => current_user, :account => current_account,
    #  :args => {:future_ids => future_ids, :listing_url => self.absolute_url(current_domain.get_config(:listing_show_path)), 
    #  :forgot_password_url => forgot_password_parties_url, :domain_name => current_domain.name} )  
    
    @futures = future_ids.collect { |id| Future.find id }
    
    respond_to do |format|
      format.js
      format.html
    end
    
    #redirect_to show_collection_futures_url(:ids => future_ids, :return_to => results_rets_path(:ids => future_ids))
  end
  
  def listings_search
    @search = (params[:search] || {}).symbolize_keys.reverse_merge(:resource => "Property", :class => "11", :limit => 5)
    find_default_resource_class_fields

    @mls_number_field     = lookup_field(@fields, "MLS Number")
    @list_date_field      = lookup_field(@fields, "List Date")
    @street_address_field = lookup_field(@fields, "Address")
    @postal_code_field    = lookup_field(@fields, "Postal Code")
    @list_price_field     = lookup_field(@fields, "List Price")

    @status_field         = lookup_field(@fields, "Status")
    @status               = lookup_values(@search[:resource], @status_field)

    @city_field           = lookup_field(@fields, "City")
    @cities               = lookup_values(@search[:resource], @city_field)

    @area_field           = lookup_field(@fields, "Area")
    @areas                = lookup_values(@search[:resource], @area_field)

    @dwelling_style_field = lookup_field(@fields, "Style of Home")
    @dwelling_styles      = lookup_values(@search[:resource], @dwelling_style_field)

    @dwelling_type_field  = lookup_field(@fields, "Type of Dwelling")
    @dwelling_types       = lookup_values(@search[:resource], @dwelling_type_field)

    @title_of_land_field  = lookup_field(@fields, "Title to Land")
    @title_of_lands       = lookup_values(@search[:resource], @title_of_land_field)

    @bedrooms_field       = lookup_field(@fields, "Total Bedrooms")
    @bathrooms_field      = lookup_field(@fields, "Total Baths")

    delete_default_fields

    respond_to do |format|
      format.js
      format.html
    end
  end

  def do_listings_search
    if !params[:area_points].blank? && params[:search_using] == "Google Map" then
      polygon = Polygon.new(:points => params[:area_points])
      params[:line]["7"][:operator] = "eq"
      params[:line]["7"][:from]     = polygon.to_geocodes.map(&:zip).map {|zip| "%s %s" % [zip.first(3), zip.last(3)]}.join(",")
      # Even though RETS returns postal codes without spaces, we have
      # to query *with* the space, or else the query will return bogus results
    end

    line_params = params[:line].clone
    line_params["1"]["from"].upcase!
    line_params.delete_if { |key,value| value["from"].blank? && value["to"].blank? }
    
    @future = RetsSearchFuture.new(
      :owner      => current_user,
      :account    => current_account,
      :args       => {
        :search   => (params[:search] || {}).symbolize_keys,
        :lines    => (line_params || {}).values.map(&:symbolize_keys),
        :polygon  => params[:area_points]
      },
      :result_url => results_rets_path(:id => "_id_")
    )
    @future.interval = Period.parse(params[:search][:repeat_interval]).as_seconds if params[:search] && !params[:search][:repeat_interval].blank?
    @future.save!
    
    future_ids = []
    future_ids << @future.id
    
    #ListingNewsletterMailSender.create!(:owner => current_user, :account => current_account,
    #  :args => {:future_ids => future_ids, :listing_url => listing_url(:id => "__id__"), 
    #  :forgot_password_url => forgot_password_parties_url, :domain_name => current_domain.name} ) 
    
    respond_to do |format|
      format.js
      format.html
    end
    
    #rescue
    #  RAILS_DEFAULT_LOGGER.debug("%%% FAILURE!!")
    #  logger.warn $!
    #  logger.warn $!.backtrace.join("\n")
    #  flash_failure @future.errors.full_messages.join("; ")

    #  redirect_to :action => :listings_search
    #render :text => 'COMPLETE'
  end
  
  def new_search_line
    @last_counter_of_search_lines = params[:last_counter_of_search_lines] || 0
    @last_counter_of_search_lines = @last_counter_of_search_lines.to_i + 1
    @search = (params[:search] || {}).symbolize_keys.reverse_merge(:resource => "Property", :class => "11", :limit => 5)
    find_default_resource_class_fields
    delete_default_fields
    respond_to do |format|
      format.js
    end

  end
  
  protected
  
  def assemble_records(raw_records)
    records = []
    raw_records.each do |listing|
    price = listing.price.format(:no_cents, :with_currency)
    # price should be in form [currency_sign]XXXXXX[currency_name] at this point
    num = price.slice!(/\d+/)
    if num.nil?
      price = "No info"
    else
      price = price[0..0] << num.reverse.scan(/\d{1,3}/).join(',').reverse << price[1..-1]
    end
      record = {
        'id' => listing.id,
        'mls_no' => listing.mls_no,
        'address' => (listing.address ? listing.address.line1 : ""),
        'area' => listing.area,
        'city' => listing.city,
        'style' => listing.style,
        'no_bed_bath' => "#{listing.bedrooms}/#{listing.bathrooms}",
        'sqft' => listing.size,        
        'price' => price.to_s,
        'description' => listing.description,
        'list_date' => listing.created_at.to_s,
        'last_transaction' => listing.updated_at.to_s,
        'status' => listing.status,
        'contact' => listing.contact_email,
        'dwelling_type' => listing.dwelling_type,
        'dwelling_class' => listing.dwelling_class,
        'title_of_land' => listing.title_of_land,
        'year_built' => listing.year_built,
        'num_of_images' => listing.num_of_images,
        'extras' => listing.extras.blank? ? "None" : listing.extras,
        'tags' => listing.tag_list,
        'picture_ids' => listing.pictures.collect { |picture| picture.id }
      }
      records.push record
    end
    records
  end
    
  def load_operators
    @operators = [
      ["Exactly equals", :eq],
      ["Starts with",  :start],
      ["Contains",  :contain],
      ["Between",  :between],
      ["Greater than",  :greater],
      ["Less than",  :less]
    ]
  end

  def find_default_resource_class_fields
    @resources = RetsMetadata.find_all_resources
    @selected_resource = @resources.detect {|row| row.first =~ /property/i}
    if @selected_resource then
      @search[:resource] = @selected_resource.last
      @classes = RetsMetadata.find_all_classes(@selected_resource.last)
      @selected_class = @classes.detect {|row| row.first =~ /cross property/i}
      if @selected_class then
        @search[:class] = @selected_class.last
        @fields = RetsMetadata.find_all_fields(@selected_resource.last, @selected_class.last)
      else
        @fields = []
      end
    else
      @classes = []
      @fields = []
    end
  end

  def load_common_tags
    @common_tags = current_account.listings.tags(:limit => 20)
  end
  
  def delete_default_fields
    ["MLS Number", "List Date", "Status", "City", "Area", "Address", "Postal Code", "List Price", "Style of Home", \
    "Type of Dwelling", "Dwelling Classification", "Title to Land", "Total Bedrooms", "Total Baths"].each do |desc|
      @fields.delete_if {|e| e.description == desc}
    end    
  end

  def check_account_authorization
    return if current_account.options.rets_import?
    @authorization = "RETS"
    access_denied
  end

  def access_denied(message="Not Found")
    flash[:notice] = message unless message.blank?
    respond_to do |format|
      format.html { render(:missing, :status => "404 Not Found") }
      format.js do
        render :update, :status => "404 Not Found" do |page|
          page << "Ext.Msg.alert('Warning', '404 Not Found');"
          page << "xl.maskedPanels.each(function(component){component.el.unmask();});"
        end
      end
    end
    false
  end

  def lookup_field(fields, name)
    fields.detect {|e| e.description == name} || OpenStruct.new(:description => name, :value => "", :stubbed? => true)
  end

  def lookup_values(resource, field)
    field.stubbed? ? [] : RetsMetadata.find_lookup_values(resource, field.lookup_name)
  end
  
  def assemble_rets(records)
    results = []
    records.each do |record|
      results << truncate_rets(record)
    end
    results
  end

  def strftime(time)
    time ? time.strftime("%b %d, %Y, %H:%M #{time.zone}") : ""
  end

  def truncate_rets(record)
    {
      :id => record.id,
      :status => record.humanize_status, 
      :started_at => strftime(record.started_at),
      :created_at => strftime(record.created_at),
      :ended_at => strftime(record.ended_at),
      :updated_at => strftime(record.updated_at),
      :scheduled_at => strftime(record.scheduled_at), 
      :interval => record.interval, 
      :progress => record.progress.to_s, 
      :tag_list => (record.args[:search][:tag_list] rescue "")
    }
  end
end
