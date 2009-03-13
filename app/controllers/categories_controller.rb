#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class CategoriesController < ApplicationController
  required_permissions %w(index) => true, %w(new edit create update destroy_collection) => :edit_categories

  before_filter :load_category, :only => %w(edit update)

  def async_get_name_id_hashes
    categories = current_account.categories.find :all, :order => "name"
    name_ids = []
    name_ids += [{ 'name' => 'New Category', 'id' => params[:with_new_category] }] if params[:with_new_category]  
    name_ids += categories.collect { |category| { 'name' => category.name, 'id' =>  category.id } }
    
    wrapper = {'total' => name_ids.size, 'collection' => name_ids}
    render :json => wrapper.to_json, :status => 200
  end
    
  def index
    respond_to do |format|
      format.js
      format.json do
        render :json => build_category_collection_tree_panel_hashes.to_json
      end
    end
  end

  def new
    @category = current_account.categories.build
  end

  def create
    @category = current_account.categories.build(params[:category])
    @created = @category.save
    respond_to do |format|
      format.js do
        return render_json_response
      end
    end
  end

  def edit
    respond_to do |format|
      format.js
    end
  end

  def update
    Category.transaction do
      @category.attributes = params[:category]
      @updated = @category.save
      if @updated then
        flash_success :now, "Category updated"      
        respond_to do |format|
          format.js { render :json => {:success => true, :flash => flash[:notice].to_s}.to_json}
        end
      else
        respond_to do |format|
          format.js do
            @category_id = true
            return render_json_response
          end
        end
      end
    end
  end

  def destroy_collection
    destroyed_items_size = 0
    current_account.categories.find(params[:ids].split(",").map(&:strip)).to_a.each do |category|
       destroyed_items_size += 1 if category.destroy
    end
    message = "#{destroyed_items_size} category(s) successfully deleted"
    success = destroyed_items_size > 0 ? true : false
    respond_to do |format|
      format.js do
        render :json => {:success => success, :flash => message}.to_json
      end
    end
  end

  protected
  def load_category
    @category = current_account.categories.find(params[:id])
  end
  
  def build_category_collection_tree_panel_hashes
    out = []
    root_categories = Category.find_all_roots(self.current_account)
    root_categories.each do |root_category|
      out << assemble_record_tree_panel_hash(root_category)
    end
    out
  end
  
  def assemble_record_tree_panel_hash(record)
    hash = {:id => record.id, :text => "#{record.name}  |  #{record.label}"}
    if record.children.count > 0
      children_hashes = []
      record.children.find(:all, :order => "name").each do |record_child|
        children_hashes << assemble_record_tree_panel_hash(record_child)
      end
      hash.merge!(:children => children_hashes)
    else
      hash.merge!(:leaf => true)
    end
    hash
  end

  def render_json_response
    errors = (@category.errors.full_messages.blank? ? ($! ? $!.message : "")  : render_to_string(:partial => "/shared/error_messages_for", :locals => {:symbol => :category})).to_s
    render :json => {:flash => flash[:notice].to_s, :close => @updated && @close, :errors => errors, 
                     :id => @category.id, :success => @updated || @created }.to_json
  end    
end
