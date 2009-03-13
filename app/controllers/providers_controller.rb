#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ProvidersController < ApplicationController
  required_permissions :none
  
  before_filter :load_product, :except => [:create, :update, :async_get_formatted_all_suppliers, :destroy_collection]
  before_filter :load_provider, :only => [:update]
  
  # RETURNS
  # format.js: {'total': X, 'collection': [{'id': X, 'name': 'Someone', 'phone': '(XXX) YYY-ZZZZ' and so on}]
  def index
    respond_to do |format|
      format.js do
        records = assemble_records(@product.providers)
        render :json => {:total => records.length, :collection => records}.to_json
      end
    end
  end
  
  def create
    if current_account.suppliers.find(:all).size == 0
      render :json => 0 # No suppliers in DB, cannot make provider
      return
    end
    
    begin
      @provider = current_account.providers.build(params[:provider])
      @provider.save!
      respond_to do |format|
        format.js do
          render :json => @provider.id
        end
      end
    rescue ActiveRecord::RecordInvalid
      # User needs to set supplier for unset record first
      render :json => -1 
    end
  end
  
  def update
    key = params[:provider].keys[0] # Get the attribute we need
    
    begin
      @provider.attributes = params[:provider]
      @provider.save!
      respond_to do |format|
        format.js do
          value = @provider.send(key).to_s
          if key == 'supplier_id' then value = {:id => value.to_i, :name => @provider.supplier.name} end
          render :json => value.to_json
        end
      end
    rescue ActiveRecord::RecordInvalid
      # Supplier is already in use
      render :json => {:name => 'Supplier Name', :id => 0}.to_json
    end
  end

  def destroy_collection
    destroyed_items_size = 0
    current_account.providers.find(params[:ids].split(",").map(&:strip)).to_a.each do |provider|
      destroyed_items_size += 1 if provider.destroy
    end
    
    respond_to do |format|
      format.js do
        render :json => destroyed_items_size
      end
    end
  end
  
  def async_get_formatted_all_suppliers
    suppliers = current_account.suppliers.find :all
    records = suppliers.collect do |supplier|
      {
        :name => supplier.name,
        :id => supplier.id
      }
    end
    wrapper = {:total => records.length, :collection => records}
    render :json => wrapper.to_json
  end
  
  protected
  
  def assemble_records(providers)
    records = providers.collect do |provider|
      supplier = provider.supplier
      # supplier could be nil because its id is 0 because
      # when a new Provider is created, its supplier_id is
      # set to 0, so we have to check for that
      {
        :id => provider.id,
        :supplier_id => {
          :name => supplier.nil? ? 'Supplier Name' : supplier.name,
          :id => supplier.nil? ? 0 : supplier.id
        },
        :phone => supplier.nil? ? '(Supplier Not Set)' : supplier.phone.formatted_number_with_extension,
        :email => supplier.nil? ? '(Supplier Not Set)' : supplier.email.to_s,
        :wholesale_price => provider.wholesale_price.to_s,
        :last_po_at => provider.last_po_at ? provider.last_po_at.strftime("%Y/%m/%d") : "",
        :sku => provider.sku,
        :avg_delivery_time => supplier.nil? ? 0 : supplier.average_delivery_time
      }
    end
  end
  
  def load_product
    @product = current_account.products.find(params[:product_id])
  end
  
  def load_provider
    # the before_filters do not cascade!
    @provider = current_account.products.find(params[:product_id]).providers.find(params[:id])
  end
  
end
