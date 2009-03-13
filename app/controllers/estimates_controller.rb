#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class EstimatesController < ApplicationController
  required_permissions %w(index show) => [:view_estimates, :edit_estimates, {:any => true}],
    %w(new create edit update destroy tax_fields destroy_collection get_totals get_send_estimate_template) => :edit_estimates
  before_filter :load_estimate, :only => %w(show edit update destroy tax_fields get_totals)
 
  def index
    search_options = {:offset => params[:start], :limit => params[:limit]}
    search_options.merge!(:order => params[:sort].blank? ? "date DESC, number DESC" : "#{params[:sort]} #{params[:dir]}") 
    unless params[:status].blank? || params[:status] =~ /all/i
      search_conditions = {:conditions => ["status LIKE ?", params[:status]]} 
      search_options.merge!(search_conditions)
    end

    root = current_account.estimates
    blocks = []

    query_params = params[:q]
    unless query_params.blank? 
      if query_params =~ /near (\w+)/ then
        logger.info {"==> NEAR query (#{$&})"}
        logger.debug {"==> distance: #{$1}"}
        geocode = Geocode.find_by_zip($1)
        raise UnknownZip, $1 if geocode.blank?
        blocks << lambda {|root| root.nearest(geocode.latitude, geocode.longitude)}
        query_params.sub!($&, "") # Remove the consumed part of the query
      end

      if query_params =~ /within (\d+) (m(iles?)?|k(m|ilometers?)) of (\w+)/ then
        logger.info {"==> WITHIN query (#{$&})"}
        logger.debug {"==> distance: #{$1}, unit: #{$2}, zip: #{$5}"}
        geocode = Geocode.find_by_zip($5)
        distance, unit = $1, $2
        raise UnknownZip, $1 if geocode.blank?
        blocks << lambda {|root| root.within(distance.to_f, :unit => unit, :latitude => geocode.latitude, :longitude => geocode.longitude)}
        query_params.sub!($&, "") # Remove the consumed part of the query
      end

      query_params = query_params.split(/\s+/)
      query_params = query_params.map {|q| q+"*"}.join(" ")
    end

    blocks.push(lambda {|root| root.search(query_params, search_options)})
    root = blocks.inject(root) {|root, block| block.call(root) }
    @estimates = root
    @estimates_count = root.length

    respond_to do |format|
      format.html
      format.js
      format.json do
        render(:json => {:total => @estimates_count, :collection => assemble_records(@estimates)}.to_json)
      end
    end

  rescue UnknownZip
    flash_failure :now, "Zip/Postal Code #{$!.message} is unknown in our database"
    logger.info {"==> Unknown zip!"}
    respond_to do |format|
      format.html
      format.js
      format.json do
        render(:json => {})
      end
    end
  end
  
  def new
    @estimate = current_account.estimates.build
    @estimate.invoice_to = current_account.parties.find(params[:invoice_to_id]) if params[:invoice_to_id]

    @common_estimate_tags = current_account.estimates.tags(:order => "count DESC, name ASC")
    respond_to do |format|
      format.js
    end
  end

  def create
    @estimate = current_account.estimates.build(params[:estimate])
    
    if @estimate.save then
      @created = true
      flash_success :now, "Estimate \##{@estimate.number} successfully created"
    else
      flash_failure :now, @estimate.errors.full_messages.reject{|error| error =~ /Account|Payment can't be blank/i }
    end
    respond_to do |format|
      format.js
    end
    
    rescue
      flash_failure :now, "Please select a Date"
  end
  
  def edit
    @common_estimate_tags = current_account.estimates.tags(:order => "count DESC, name ASC")
    respond_to do |format|
      format.js
    end
  end
  
  def update
    @old_subtotal = @estimate.subtotal_amount
    @old_total = @estimate.total_amount
    
    @estimate.update_attributes(params[:estimate])
    respond_to do |format|
      format.js do
        @updated = @estimate.ship_to ? @estimate.ship_to.update_attributes(params[:ship_to]) : @estimate.create_ship_to(params[:ship_to])
        if @estimate.ship_to
          recommended_shipping_fee = current_account.destinations.shipping_cost_for_country_and_state(@estimate.ship_to.country, @estimate.ship_to.state)        
          @recommend_msg = "Recommended shipping fee: #{recommended_shipping_fee.to_s}"
        end
        if @updated then
          flash_success :now, "Estimate \##{@estimate.number} successfully updated. "
        else
          flash_failure :now, @estimate.errors.full_messages
        end
      end
    end
  end
  
  def destroy_collection
    @destroyed_items_size = 0
    current_account.estimates.find(params[:ids].split(",").map(&:strip)).to_a.each do |estimate|
      @destroyed_items_size += 1 if estimate.destroy
    end
    flash_success :now, "#{@destroyed_items_size} estimate(s) successfully deleted"
    respond_to do |format|
      format.js
    end
  end
  
  def auto_complete_tag
    @tags = current_account.folders.tags_like(params[:q])
    render_auto_complete(@tags)
  end
  
  def tax_fields
    respond_to do |format|
      format.js { render :action => "tax_fields", :layout => false }
    end
  end
  
  def get_totals
    respond_to do |format|
      format.js { render :json => json_get_totals_for(@estimate).to_json}
    end
  end
  
  def get_send_estimate_template
    send_estimate_config = current_domain.get_config("send_order_template")
    @send_estimate_template = current_account.templates.find_by_label(send_estimate_config) if send_estimate_config
    respond_to do |format|
      format.js { render :json => {:template_name => @send_estimate_template ? @send_estimate_template.label : nil}.to_json}
    end
  end

  protected
  def assemble_records(records)
    results = []
    records.each do |record|
      results << {
        :id => record.id,
        :object_id => record.dom_id, 
        :number => record.number, 
        :date => record.date.to_s, 
        :shipping_method => record.shipping_method, 
        :status => record.status, 
        :care_of_name => record.care_of_name, 
        :created_by_name => record.created_by_name, 
        :updated_by_name => record.updated_by_name, 
        :sent_by_name => record.sent_by_name, 
        :confirmed_by_name => record.confirmed_by_name, 
        :completed_by_name => record.completed_by_name, 
        :subtotal => record.subtotal_amount.to_s, 
        :total => record.total_amount.to_s,
        :invoiced_to_name => record.invoice_to ? record.invoice_to.full_name : "",
        :distance => record.distance.to_s
      }
    end
    results
  end
  
  def json_get_totals_for(estimate)
    returning(Hash.new) do |result|
      %w( labor_amount transport_fee_amount products_fst_amount total_amount subtotal_amount products_amount
          products_pst_amount equipment_fee_amount fees_amount downpayment_amount_amount pst_subtotal_amount
          fst_subtotal_amount shipping_fee_amount fees_pst_amount fees_fst_amount subtotal_and_fees_amount
          downpayment_amount fst_amount labor_fst_amount transport_fee pst_amount labor_pst_amount shipping_fee
          equipment_fee fst_rate pst_rate
      ).each do |attr|
        result[attr] = estimate.send(attr).to_s
      end
    end
  end

  private
  def load_estimate
    @estimate ||= current_account.estimates.find(params[:id])
  end

  class UnknownZip < ArgumentError; end
end
