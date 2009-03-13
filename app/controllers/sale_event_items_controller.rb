#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class SaleEventItemsController < ApplicationController
  required_permissions :none
  
  before_filter :get_sale_event
  
  before_filter :remove_uneditable_fields, :only => [:update]
  before_filter :convert_sale_price_params_to_money, :only => [:create, :update]
  
  def index
    respond_to do |format|
      format.json do
        process_index
        render(:text => JsonCollectionBuilder::build(@sale_event_items, @sale_event_items_count))
      end
    end
  end
  
  def create
    sale_event_item = @sale_event.construct_item(params[:sale_event_item])
    @created = sale_event_item.save
    if @created
      @sale_event.editor = current_user
      @sale_event.save
    end
    respond_to do |format|
      format.js do
        if @created
          render(:text => sale_event_item.reload.to_json(:message => "Sale event item successfully added"))
        else
          render(:text => {:message => "Creating sale event item failed"}.to_json)
        end
      end
    end
  end
  
  def update
    sale_event_item = @sale_event.items.find(params[:id])
    SaleEventItem.transaction do 
      sale_event_item.update_class_and_target(params[:sale_event_item].delete(:target))
      sale_event_item = @sale_event.items.find(params[:id])
      sale_event_item.class_changed = true
      sale_event_item.attributes = params[:sale_event_item]
      @updated = sale_event_item.save
      if @updated
        sale_event = sale_event_item.sale_event
        sale_event.editor = current_user
        sale_event.save
      end
    end
    respond_to do |format|
      format.js do
        if @updated
          render(:text => sale_event_item.reload.to_json(:message => "Sale event item updated"))
        else
          render(:text => {:message => "Updating sale event item failed"}.to_json)
        end
      end
    end
  end

  def destroy_collection
    @destroyed_items_size = 0
    @sale_event.items.find(params[:ids].split(",").map(&:strip)).to_a.each do |sale_event_item|
      @destroyed_items_size += 1 if sale_event_item.destroy
    end
    
    respond_to do |format|
      format.js do
        render(:text => {:message => "#{@destroyed_items_size} item(s) deleted"}.to_json)
      end
    end
  end
  
  def set_attribute_collection
    @updated_items_size = 0
    if params[:attribute] && params[:new_value]
      @sale_event.items.find(params[:ids].split(",").map(&:strip)).each do |sale_event_item|
        sale_event_item.send(params[:attribute] + "=", params[:new_value])
        @updated_items_size += 1 if sale_event_item.save
      end
    end

    respond_to do |format|
      format.js do
        render(:text => {:message => "#{@updated_items_size} item(s) updated"}.to_json)
      end
    end
  end
  
  protected
  
  def process_index
    @sale_event_items = @sale_event.items
    @sale_event_items_count = @sale_event.items.count
  end
  
  def get_sale_event
    @sale_event = current_account.sale_events.find(params[:sale_event_id])
  end
  
  def remove_uneditable_fields
    return true unless params[:sale_event_item]
    params[:sale_event_item].delete(:wholesale_price)
    params[:sale_event_item].delete(:retail_price)
    params[:sale_event_item].delete(:margin)
  end
  
  def convert_sale_price_params_to_money
    params[:sale_event_item][:sale_price] = params[:sale_event_item][:sale_price].to_money if params[:sale_event_item][:sale_price]
  end  
end
