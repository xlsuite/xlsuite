#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ProductCategoriesController < ApplicationController
  
  required_permissions :none
  
  before_filter :find_product_category, :only => %w(edit update async_update async_upload_image destroy)
  
  def index
    respond_to do |format|
      format.html
      format.js
      format.json do
        find_product_categories
        render(:json => JsonCollectionBuilder::build_from_objects(@product_categories, @product_categories_count))
      end
    end
  end
  
  def async_create
    @product_category = current_account.product_categories.build(params[:product_category])
    created = @product_category.save
    if not created
      render :json => @product_category.errors.full_messages.join(',').to_json
      return
    else
      flash_success :now, "Product Category #{@product_category.label} successfully created"
      render :json => {:id =>@product_category.id, :text => "#{@product_category.name} | #{@product_category.label}"}.to_json
    end
  end
  
  def create
    @product_category = current_account.product_categories.build(params[:product_category])
    @created = @product_category.save
    if !@created
      flash_failure :now, @product_category.errors.full_messages
    else
      flash_success :now, "Product Category #{@product_category.name} successfully created"
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
    @product_category.attributes = params[:product_category]
    @updated = @product_category.save
    if !@updated
      flash_failure :now, @product_category.errors.full_messages
    end
    respond_to do |format|
      format.js
    end
  end
  
  def async_update
    key = params[:product_category].keys[0] # Get the attribute we need
    
    if (key == 'parent_id') && (params[:product_category][key] == '0')
      params[:product_category][key] = nil
    end
    
    if key.include? '_ids'
      # Split by commas, then make them all integers
      params[:product_category][key] = params[:product_category][key].split(',').collect(&:to_i)
    end
    
    @product_category.attributes = params[:product_category]
    updated = @product_category.save
    if not updated
      flash_failure :now, @product_category.errors.full_messages
    end

    if key.include? '_ids'
      @product_category = current_account.product_categories.find(params[:id])
      render :json => @product_category.send(key).to_json
      return
    else
      errors = @product_category.errors.full_messages
      @product_category.reload
      render :json => {:success => updated, :update => @product_category.send(key).to_s, :errors => errors}.to_json
    end
  end
  
  def destroy
    @destroyed = @product_category.destroy
    respond_to do |format|
      format.js { render :json => @destroyed.to_json }
    end
  end
  
  def tree_json
    # The Tree may ask for a specific node. If it's 0 (the source node),
    # then return all the nodes by setting the test up to fail
    if params[:node] == '0' then params[:node] = nil end
    roots = Array(params[:node] ? current_account.product_categories.find(params[:node]) : current_account.product_categories.roots)
    tree = roots.collect { |root| root.to_node }
    
    render :json => tree.to_json
  end
  
  # POST request
  # INPUTS:
  #   id - id of the product
  #   file - the file object
  # OUTPUTS:
  #   On success - {url: 'http://whatever', id: X}
  #   On failure - "Error 1, Error 2"
  def async_upload_image
    Account.transaction do
      @product_category.avatar = params[:file]
      @product_category.save!
      logger.debug "%%% Assigned id"
      
      render :json => {:success => true, :message => 'Upload Successful!', :avatar_id => @product_category.avatar_id}.to_json
    end

  rescue
    @messages = []
    @messages << @picture.errors.full_messages if @picture
    @messages << @view.errors.full_messages if @view
    logger.debug "%%% #{@messages.to_yaml}"
    render :json => {:success => false, :error => @messages.flatten.delete_if(&:blank?).join(',')}.to_json
  end
  
  protected
  
  def find_product_categories
    @product_categories = current_account.product_categories.roots
    @product_categories_count = current_account.product_categories.roots.length
  end
  
  def find_product_category
    @product_category = current_account.product_categories.find(params[:id])
  end
end
