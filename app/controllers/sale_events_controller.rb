#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class SaleEventsController < ApplicationController
  required_permissions :none

  before_filter :find_common_sale_events_tags, :only => [:new, :edit]
  before_filter :find_sale_event, :only => [:edit, :update, :destroy]
  
  def index
    respond_to do |format|
      format.js
      format.json do
        process_index
        render(:text => JsonCollectionBuilder::build(@sale_events, @sale_events_count))
      end
    end
  end
  
  def new
    @sale_event = SaleEvent.new
    respond_to do |format|
      format.js
    end
  end
  
  def create
    @sale_event = current_account.sale_events.build(params[:sale_event])
    @sale_event.creator = current_user
    @created = @sale_event.save
    if @created
      flash_success :now, "Sale event #{@sale_event.name} successfully created"
    else
      flash_failure :now, @sale_event.errors.full_messages
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
    @sale_event.attributes = params[:sale_event]
    @sale_event.editor = current_user
    @updated = @sale_event.save
    if !@updated
      flash_failure :now, @sale_event.errors.full_messages
    end
    respond_to do |format|
      format.js
    end
  end
  
  def destroy
    respond_to do |format|
      format.js
    end
  end
  
  def destroy_collection
    @destroyed_items_size = 0
    current_account.sale_events.find(params[:ids].split(",").map(&:strip)).to_a.each do |sale_event|
      next unless sale_event.writeable_by?(current_user)
      @destroyed_items_size += 1 if sale_event.destroy
    end
    
    flash_success :now, "#{@destroyed_items_size} sale event(s) successfully deleted"
    respond_to do |format|
      format.js
    end
  end
  
  def tagged_collection
    @tagged_items_size = 0
    current_account.sale_events.find(params[:ids].split(",").map(&:strip)).to_a.each do |sale_event|
      next unless sale_event.writeable_by?(current_user)
      sale_event.tag_list = sale_event.tag_list + " #{params[:tag_list]}"
      @tagged_items_size += 1 if sale_event.save
    end
    
    respond_to do |format|
      format.js do
        flash_success :now, "#{@tagged_items_size} sale events has been tagged with #{params[:tag_list]}"
      end
    end
  end
  
  def auto_complete
    mappings = get_auto_complete_mappings
    respond_to do |format|
      format.json do
        render(:text => convert_to_auto_complete_json(mappings))
      end
    end
  end
  
  protected

  def find_common_sale_events_tags
    @common_tags = current_account.sale_events.tags(:order => "count DESC, name ASC")
  end
    
  def process_index
    @sale_events = current_account.sale_events.find(:all)
    @sale_events_count = current_account.sale_events.count
  end
  
  def find_sale_event
    @sale_event = current_account.sale_events.find(params[:id])
  end
  
  def get_auto_complete_mappings
    spacing = "&nbsp;"
    mappings = []
    all_products = ["<b>All Products</b>", "All Products", "all_products"]
    mappings << all_products;
    current_account.product_categories.roots.each do |pc_root|
      mappings += build_auto_complete_tree_structure(pc_root, 0, spacing)
    end
    mappings += current_account.products.not_in_any_category(:conditions => ["name LIKE ?", "%#{params[:query]}%"]).map {|e| [e.name, e.name, e.dom_id]}
    mappings
  end
  
  def build_auto_complete_tree_structure(category, level, spacing)
    mappings = []
    products = category.products.find(:all, :conditions => ["name LIKE ?", "%#{params[:query]}%"]).map {|e| [spacing * (level+1) + e.name, e.name, e.dom_id]}
    if products.size > 0
      mappings << ["<b>" + spacing * level + category.name + "</b>", category.name, category.dom_id]
      mappings += products
    end
    if category.children.count > 0
      category.children.each do |pc|
        mappings += build_auto_complete_tree_structure(pc, level+1, spacing)
      end
    end
    mappings
  end
end
