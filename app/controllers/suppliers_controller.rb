#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class SuppliersController < ApplicationController
  required_permissions :none

  before_filter :find_common_suppliers_tags, :only => [:new, :edit]
  before_filter :find_supplier, :only => [:edit, :update, :destroy, :async_update, :async_get_attribute, :async_get_group_auths_json]

  def index
    respond_to do |format|
      format.js
      format.json do
        process_index
        render :json => {:total => @suppliers_count, :collection => assemble_records(@suppliers)}.to_json
      end
    end
  end

  def new
    @supplier = Supplier.new
    respond_to do |format|
      format.js
    end
  end

  def async_create
    @supplier = current_account.suppliers.build(params[:supplier])
    @supplier.creator = current_user
    @created = false
    begin
      @created = @supplier.save
    rescue ActiveRecord::RecordInvalid
    end
    if @created
      flash_success :now, "Supplier #{@supplier.name} successfully created"
      render :json => @supplier.id
      return
    else
      error_messages = @supplier.errors.full_messages
      error_messages += @supplier.entity.errors.full_messages
      flash_failure :now, error_messages
      render :json => error_messages.join(', ')
      return
    end
  end
  
  def create
    @supplier = current_account.suppliers.build(params[:supplier])
    @supplier.creator = current_user
    @created = false
    begin
      @created = @supplier.save
    rescue ActiveRecord::RecordInvalid
    end
    if @created
      flash_success :now, "Supplier #{@supplier.name} successfully created"
    else
      error_messages = @supplier.errors.full_messages
      error_messages += @supplier.entity.errors.full_messages
      flash_failure :now, error_messages
    end
    respond_to do |format|
      format.js
    end
  end

  def edit
    respond_to do |format|
      format.js
    end
  end

  def update
    @supplier.attributes = params[:supplier]
    @supplier.editor = current_user
    @updated = false
    begin  
      @updated = @supplier.save  
    rescue ActiveRecord::RecordInvalid
    end
    if !@updated
      error_messages = @supplier.errors.full_messages
      error_messages += @supplier.entity.errors.full_messages
      error_messages += @supplier.email.errors.full_messages
      error_messages += @supplier.link.errors.full_messages
      error_messages += @supplier.phone.errors.full_messages
      flash_failure :now, error_messages
    end
    respond_to do |format|
      format.js
    end
  end

  def async_update
    key = params[:supplier].keys[0] # Get the attribute we need
    
    if key.include? '_ids'
      # Split by commas, then make them all integers
      params[:supplier][key] = params[:supplier][key].split(',').collect(&:to_i)
    end
    
    @supplier.attributes = params[:supplier]
    @supplier.editor = current_user
    @updated = false
    begin  
      @updated = @supplier.save  
    rescue ActiveRecord::RecordInvalid
    end
    
    if !@updated
      error_messages = @supplier.errors.full_messages
      error_messages += @supplier.entity.errors.full_messages
      error_messages += @supplier.email.errors.full_messages
      error_messages += @supplier.link.errors.full_messages
      error_messages += @supplier.phone.errors.full_messages
      flash_failure :now, error_messages
    end
    
    if key.include? '_ids'
      @supplier = current_account.suppliers.find(params[:id])
      render :json => @supplier.send(key).to_json
      return
    else
      render :json => @supplier.send(key).to_s.to_json
    end
  end
  
  def async_get_attribute
    render :json => @supplier.send(params[:attribute]).to_s.to_json
  end
  
  def async_get_group_auths_json
    render :json => {:writer_ids => @supplier.writer_ids, :reader_ids => @supplier.reader_ids}.to_json
  end
  
  def destroy
    respond_to do |format|
      format.js
    end
  end

  def destroy_collection
    @destroyed_items_size = 0
    current_account.suppliers.find(params[:ids].split(",").map(&:strip)).to_a.each do |supplier|
      next unless supplier.writeable_by?(current_user)
      @destroyed_items_size += 1 if supplier.destroy
    end

    flash_success :now, "#{@destroyed_items_size} supplier(s) successfully deleted"
    respond_to do |format|
      format.js
    end
  end

  def tagged_collection
    @tagged_items_size = 0
    current_account.suppliers.find(params[:ids].split(",").map(&:strip)).to_a.each do |supplier|
      next unless supplier.writeable_by?(current_user)
      supplier.tag_list = supplier.tag_list + " #{params[:tag_list]}"
      @tagged_items_size += 1 if supplier.save
    end

    respond_to do |format|
      format.js do
        flash_success :now, "#{@tagged_items_size} supplier(s) has been tagged with #{params[:tag_list]}"
      end
    end
  end
  
  protected

  def assemble_records(records)
    timestamp_format = "%d/%m/%Y"
    results = []
    records.each do |record|
      results << {
        :id => record.id,
        :object_id => record.dom_id,
        :name => record.name, 
        :current_po_status => record.current_po_status, 
        :threshold_products => record.threshold_products,
        :total_products => record.total_products,
        :last_order_at => record.last_order_at ? record.last_order_at.strftime(timestamp_format) : "",
        :last_delivery_at => record.last_delivery_at ? record.last_delivery_at.strftime(timestamp_format) : "",
        :average_delivery_time => record.average_delivery_time,
        :average_margin => record.average_margin,
        :writer_ids => record.writer_ids,
        :reader_ids => record.reader_ids
      }
    end
    results
  end



  def find_common_suppliers_tags
    @common_tags = current_account.suppliers.tags(:order => "count DESC, name ASC")
  end

  def process_index
    @suppliers = current_account.suppliers.find(:all)
    @suppliers_count = current_account.suppliers.count
  end

  def find_supplier
    @supplier = current_account.suppliers.find(params[:id])
  end
end
