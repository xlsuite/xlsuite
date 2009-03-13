#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ProductItemsController < ApplicationController
  required_permissions :none 

  def index
    respond_to do |format|
      format.js
      format.json do
        case params[:type] 
        when /asset/i
          @objects = @product.accessible_assets
          @objects_count = @product.accessible_assets.count
          return render(:json => {:collection => self.assemble_assets(@objects), :total => @objects_count}.to_json)
        when /group/i
          @object_ids = @product.accessible_items.all(:select => "item_id", :conditions => {:item_type => "group"}).map(&:item_id)
          return render(:json => self.build_group_collection_tree_panel_hashes(@object_ids).to_json)
        when /blog/i
          @object_ids = @product.accessible_items.all(:select => "item_id", :conditions => {:item_type => "blog"}).map(&:item_id)
          @objects = self.current_account.blogs
          @objects_count = self.current_account.blogs.count
          return render(:json => {:collection => self.assemble_blogs(@objects, @object_ids), :total => @objects_count}.to_json)
        else
          raise StandardError, "Type not supported"
        end            
      end
    end
  end
  
  def create
    @item = params[:item_type].classify.constantize.find(params[:item_id])
    @product_item = ProductItem.new(:item => @item, :product => @product)
    @created = @product_item.save
    respond_to do |format|
      format.js do
        render(:json => {:success => @created}.to_json)
      end
    end
  end
  
  def destroy_collection
    @destroyed_items_size = 0
    ProductItem.all(:conditions => {:product_id => @product.id, :item_id => params[:item_ids].split(","), :item_type => params[:item_type]}).each do |product_item|
      @destroyed_items_size += 1 if product_item.destroy
    end
    
    respond_to do |format|
      format.js do
        render(:json => {:success => true, :total => @destroyed_item_size}.to_json)
      end
    end
  end

  protected
  
  def assemble_blogs(records, included_blog_ids)
    out = []
    records.each do |record|
      out << self.truncate_blog(record, included_blog_ids)
    end
    out
  end
  
  def truncate_blog(record, included_blog_ids)
    {
      :id => record.id,
      :title => record.title,
      :subtitle => record.subtitle,
      :author_name => record.author_name,
      :checked => included_blog_ids.include?(record.id)
    }
  end
  
  def build_group_collection_tree_panel_hashes(included_group_ids)
    out = []
    root_groups = self.current_account.groups.find(:all, :conditions => "parent_id IS NULL", :order => "name")
    root_groups.each do |root_group|
      out << self.assemble_record_tree_panel_hash(root_group, included_group_ids)
    end
    out
  end
  
  def assemble_record_tree_panel_hash(record, included_group_ids=[])
    hash = {:id => record.id, :text => "#{record.name}  |  #{record.label}"}
    hash.merge!(:checked => true) if included_group_ids.include?(record.id)
    if record.children.count > 0
      children_hashes = []
      record.children.find(:all, :order => "name").each do |record_child|
        children_hashes << self.assemble_record_tree_panel_hash(record_child, included_group_ids)
      end
      hash.merge!(:children => children_hashes)
    else
      hash.merge!(:leaf => true)
    end
    hash
  end

  def assemble_assets(records)
    out = []
    records.each do |record|
      out << self.truncate_asset(record)
    end
    out
  end
  
  def truncate_asset(record)
    {
      :id => record.id,
      :dom_id => record.dom_id,
      :label => record.filename,
      :type => record.content_type,
      :folder => record.folder_name,
      :size => record.humanized_size,
      :path => record.path,
      :z_path => record.z_path,
      :absolute_path => record.src,
      :notes => record.description,
      :tags => record.tag_list,
      :created_at => record.created_at.strftime(DATE_STRFTIME_FORMAT),
      :updated_at => record.updated_at.strftime(DATE_STRFTIME_FORMAT),
      :url => record.thumbnail_path
    }
  end
  
  def authorized?
    return unless self.current_user?
    @product = Product.find(params[:product_id])
    @product.writeable_by?(self.current_user)
  end
end
