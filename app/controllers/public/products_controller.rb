#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Public::ProductsController < ApplicationController
  # check authorized?
  required_permissions :none
  before_filter :blacklist_parameters, :only => [:update]
  before_filter :load_product_categories, :only => [:add_to_categories, :remove_from_categories]
  
  def create
    begin
      ActiveRecord::Base.transaction do
        main_image_params = params[:product].delete("main_image")
        
        @product = self.current_account.products.build(params[:product])
        @product.creator = self.current_user
        p_owner = nil
        if params[:owner_profile_id]
          p_owner = self.current_account.profiles.find(params[:owner_profile_id]).party
        else
          p_owner = self.current_user
        end
        @product.private = true
        @product.owner = p_owner
        @product.current_domain = current_domain
        @product.save!
        
        unless main_image_params.blank? || main_image_params.size == 0 then
          product_main_image_id = @product.main_image_id
          Asset.find(product_main_image_id) if product_main_image_id
          main_image = self.current_account.assets.build(:uploaded_data => main_image_params, :account => @product.account)
          main_image.crop_resized("70x108")
          main_image.save!
          @product.main_image = main_image.id
        end
              
        respond_to do |format|
          format.html do
            flash_success params[:success_message] || "Product #{@product.name} successfully created"
            @_target_id = @product.id
            return redirect_to_next_or_back_or_home
          end
          format.js do
            render :json => {:success => true}
          end
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
  
  def update
    begin
      ActiveRecord::Base.transaction do
        main_image_params = params[:product].delete("main_image")

        @product.attributes = params[:product]
        @product.editor = self.current_user
        @product.save!

        unless main_image_params.blank? || main_image_params.size == 0 then
          product_main_image_id = @product.main_image_id
          Asset.find(product_main_image_id) if product_main_image_id
          main_image = self.current_account.assets.build(:uploaded_data => main_image_params, :account => @product.account)
          main_image.crop_resized("70x108")
          main_image.save!
          @product.main_image = main_image.id
        end

        respond_to do |format|
          format.html do
            flash_success params[:success_message] || "Product #{@product.name} successfully updated"
            return redirect_to_next_or_back_or_home
          end
          format.js do
            render :json => {:success => true}
          end
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
  
  def destroy
    name = @product.name
    @destroyed = @product.destroy
    if @destroyed
      flash_success params[:success_message] || "Product #{name} successfully destroyed"
    else
      errors = $!.message.to_s
      flash_failure errors
    end
    respond_to do |format|
      format.html do
        return @destroyed ? redirect_to_next_or_back_or_home : redirect_to_return_to_or_back_or_home
      end
      format.js do
        render :json => {:success => @destroyed, :errors => [errors]}
      end
    end
  end
  
  def add_to_categories
    errors, messages = [], []
    if @all_categories_permitted
      @product.add_to_category_ids!(@category_ids_param)
      messages << "Product successfully added to the categories"
    else
      errors << "Access allowed only for public categories"
    end
    respond_to do |format|      
      format.html do
        if @all_categories_permitted
          flash_success messages.first
        else
          flash_failure errors.first
        end
        return @all_categories_permitted ? redirect_to_next_or_back_or_home : redirect_to_return_to_or_back_or_home
      end
      format.js do
        render :json => {:success => @all_categories_permitted, :errors => errors, :messages => messages}
      end
    end
  end
  
  def remove_from_categories
    errors, messages = [], []
    if @all_categories_permitted
      @product.category_ids = (@product.category_ids - @category_ids_param).uniq
      @product.save!
      messages << "Product successfully removed from the categories"
    else
      errors << "Access allowed only for public categories"
    end
    respond_to do |format|
      format.html do
        if @all_categories_permitted
          flash_success messages.first
        else
          flash_failure errors.first
        end
        return @all_categories_permitted ? redirect_to_next_or_back_or_home : redirect_to_return_to_or_back_or_home
      end
      format.js do
        render(:json => {:success => @all_categories_permitted, :errors => errors, :messages => messages})
      end
    end
  end
  
  protected
  def load_product
    @product = self.current_account.products.find(params[:id])
  end
  
  def load_product_categories
    @category_ids_param = params[:category_ids].split(",").map(&:strip).map(&:to_i)
    @product_categories_count = self.current_account.product_categories.count(:conditions => {:id => @category_ids_param, :private => false})
    @all_categories_permitted = @category_ids_param.size == @product_categories_count
  end
  
  def blacklist_parameters
    if params[:product]
      params[:product].delete(:category_ids)
    end
  end
  
  def authorized?
    #index new create edit update destroy
    if %w(update destroy add_to_categories remove_from_categories).include?(self.action_name)
      return false unless self.current_user?
      self.load_product
      return true if self.current_user.can?(:edit_products)
      return true if @product.creator_id == self.current_user.id || @product.owner_id == self.current_user.id
    elsif %w(create).include?(self.action_name)
      return false unless self.current_user?
      return true
    end
    false
  end      
end
