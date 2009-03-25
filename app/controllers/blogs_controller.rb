#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class BlogsController < ApplicationController
  # check authorized?
  required_permissions :none
  
  before_filter :load_blog, :only => [:edit, :update, :approve_comments, :read_access_groups]
  
  def index
    respond_to do |format|
      format.js
      format.json do
        load_blogs
        render :json => {:collection => assemble_records(@blogs), :total => @blogs_count}.to_json
      end
    end
  end
  
  def new
    @blog = Blog.new(:author_name => current_user.name.to_s)
    respond_to do |format|
      format.js
    end
  end
  
  def create
    @blog = self.current_account.blogs.build(params[:blog])
    @blog.created_by = self.current_user
    @blog.updated_by = self.current_user
    @blog.domain = self.current_domain
    @created = @blog.save
    @close = true if params[:commit_type] && params[:commit_type] =~ /close/i
    respond_to do |format|
      format.js do
        render_json_response
      end
    end
  end
  
  def edit
    respond_to do |format|
      format.js
    end
  end
  
  def update
    @blog.attributes = params[:blog]
    @blog.reader_ids = @blog.reader_ids unless params[:blog][:reader_ids]
    @blog.updated_by = current_user
    if @blog.save
      @updated = true
      @close = true if params[:commit_type] && params[:commit_type] =~ /close/i
      flash_success :now, "Blog #{@blog.title} successfully updated" if @updated
    end
    respond_to do |format|
      format.js do
        if params[:from_index]
          render :json => json_response_for(@blog).to_json
        else
          render_json_response
        end
      end
    end
  end
  
  def destroy_collection
    @destroyed_items_size = 0
    @undestroyed_items_size = 0
    current_account.blogs.find(params[:ids].split(",").map(&:strip)).to_a.each do |blog|
      if blog.destroy
        @destroyed_items_size += 1
      else
        @undestroyed_items_size += 1
      end
    end

    error_message = []
    error_message << "#{@destroyed_items_size} blog(s) successfully deleted" if @destroyed_items_size > 0
    error_message << "#{@undestroyed_items_size} blog(s) failed to be destroyed" if @undestroyed_items_size > 0

    flash_success :now, error_message.join(", ")
    respond_to do |format|
      format.js
    end
  end
  
  def approve_comments
    blog_posts = @blog.posts.find(params[:blog_ids].split(","))
    count = 0
    blog_posts.each do |blog_post|
      count += blog_post.approve_all_comments
    end
    flash_success :now, "#{count} comments has been approved"
    respond_to do |format|
      format.js
    end
  end
  
  def read_access_groups
    respond_to do |format|
      format.json do
        render(:json => build_group_collection_tree_panel_hashes.to_json)
      end
    end
  end
    
  protected

  def build_group_collection_tree_panel_hashes
    out = []
    root_groups = current_account.groups.find(:all, :conditions => "parent_id IS NULL", :order => "name")
    root_groups.each do |root_group|
      out << assemble_record_tree_panel_hash(root_group, @blog)
    end
    out
  end
  
  def assemble_record_tree_panel_hash(record, object=nil)
    hash = {:id => record.id, :text => "#{record.name}  |  #{record.label}"}
    if object
      hash.merge!(:checked => true) if object.reader_ids.index(record.id)
    end
    if record.children.count > 0
      children_hashes = []
      record.children.find(:all, :order => "name").each do |record_child|
        children_hashes << assemble_record_tree_panel_hash(record_child, object)
      end
      hash.merge!(:children => children_hashes)
    else
      hash.merge!(:leaf => true)
    end
    hash
  end

  
  def load_blogs
    search_options = {:offset => params[:start], :limit => params[:limit], :order => "created_at DESC"}
    search_options.merge!(:order => "#{params[:sort]} #{params[:dir]}") if params[:sort]

    query_params = params[:q]
    unless query_params.blank?
      query_params = query_params.split(/\s+/)
      query_params = query_params.map {|q| q+"*"}.join(" ")
    end

    @blogs = current_account.blogs.search(query_params, search_options)
    @blogs_count = current_account.blogs.count_results(query_params)
  end
  
  def load_blog
    @blog = current_account.blogs.find(params[:id])
  end
  
  def assemble_records(records)
    results = []
    records.each do |record|
      results << truncate_record(record)
    end
    results
  end

  def truncate_record(record)
    {
      :id => record.id,
      :object_id => record.dom_id,
      :title => record.title,
      :subtitle => record.subtitle,
      :label => record.label,
      :posts_count => record.posts.count,
      :author_name => record.author_name
    }
  end
  
  def json_response_for(record)
    json_response = truncate_record(record.reload)
    json_response.merge!(:flash => flash[:notice].to_s)
    json_response
  end

  def render_json_response
    errors = (@blog.errors.full_messages.blank? ? ($! ? $!.message : "")  : render_to_string(:partial => "/shared/error_messages_for", :locals => {:symbol => :blog})).to_s
    render :json => {:flash => flash[:notice].to_s, :close => @updated && @close, :errors => errors, 
                     :id => @blog.id, :success => @updated || @created }.to_json
  end
  
  def authorized?
    #index new create edit update destroy_collection approve_comments
    if %w(edit update approve_comments).index(self.action_name)
      return false unless current_user?
      return true if current_user.can?(:edit_blogs)
      self.load_blog
      return true if @blog.created_by_id == current_user.id || @blog.owner_id == current_user.id
    else
      return false unless current_user?
      return true if current_user.can?(:edit_blogs)
    end
    false
  end      
end
