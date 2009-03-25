#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class BlogPostsController < ApplicationController
  required_permissions :none
  
  before_filter :load_blogs, :only => [:new, :edit]
  before_filter :load_blog_post, :only => [:edit, :update]
  
  def index
    respond_to do |format|
      format.js
      format.json do
        load_blog_posts
        render :json => {:collection => assemble_records(@blog_posts), :total => @blog_posts_count}.to_json
      end
    end
  end
  
  def new
    @blog_post = BlogPost.new
    @default_blog = @blogs.first
    if params[:blog_id]
      @blog = current_account.blogs.find(params[:blog_id])
      @blog_post.blog = @blog
      @default_blog = @blog
    end
    respond_to do |format|
      format.js
    end
  end
  
  def create
    published_at = params[:blog_post][:published_at]
    @blog_post = current_account.blog_posts.build(params[:blog_post])
    if published_at
      if params[:published_at]
        hour = params[:published_at][:hour].to_i
        hour += 12 if params[:published_at][:ampm] =~ /PM/
        published_at = published_at.utc.change(:hour => hour, :min => params[:published_at][:min]) if published_at.respond_to?(:utc)
      end
      @blog_post.published_at = published_at
    end
    @blog = self.current_account.blogs.find(params[:blog_id])
    @blog_post.blog = @blog
    @blog_post.current_domain = self.current_domain
    @blog_post.domain = self.current_domain
    @blog_post.author = self.current_user
    @blog_post.hide_comments = params[:blog_post][:hide_comments] ? true : false
    @created = @blog_post.save
    @close = true if params[:commit_type] && params[:commit_type] =~ /close/i
    respond_to do |format|
      format.html do
        unless @created
          flash_failure @blog_post.errors.full_messages
        end
        redirect_to_return_to_or_back
      end
      format.js do
        render_json_response
      end
    end
  end
  
  def edit
    @default_blog = @blog_post.blog
    @formatted_comments_path = formatted_comments_path(:commentable_type => "BlogPost", :commentable_id => @blog_post.id, :format => :json)
    @edit_comment_path = edit_comment_path(:commentable_type => "BlogPost", :commentable_id => @blog_post.id, :id => "__ID__")
    respond_to do |format|
      format.js
    end
  end
  
  def update
    published_at = params[:blog_post][:published_at]

    @blog_post.attributes = params[:blog_post]
    @blog_post.editor = current_user
    if published_at
      if params[:published_at]
        hour = params[:published_at][:hour].to_i
        hour += 12 if params[:published_at][:ampm] =~ /PM/
        published_at = published_at.utc.change(:hour => hour, :min => params[:published_at][:min]) if published_at.respond_to?(:utc)
      end
      @blog_post.published_at = published_at
    end
    @blog_post.published_at = nil if params[:disable_publish]
    @blog_post.deactivate_commenting_on = nil if params[:blog_post][:deactivate_commenting_on] == "false"
    @blog_post.hide_comments = (params[:blog_post][:hide_comments]=="false") ? false : true unless params[:blog_post][:hide_comments].blank?
    if @blog_post.save
      @updated = true
      @close = true if params[:commit_type] && params[:commit_type] =~ /close/i
      flash_success :now, "Post #{@blog_post.title} successfully updated" if @updated
    end
    respond_to do |format|
      format.js do
        if params[:from_index]
          render :json => json_response_for(@blog_post).to_json
        else
          render_json_response
        end
      end
    end
  end
  
  def destroy_collection
    @destroyed_items_size = 0
    @undestroyed_items_size = 0
    current_account.blog_posts.find(params[:ids].split(",").map(&:strip)).to_a.each do |blog_post|
      if blog_post.destroy
        @destroyed_items_size += 1
      else
        @undestroyed_items_size += 1
      end
    end

    error_message = []
    error_message << "#{@destroyed_items_size} blog post(s) successfully deleted" if @destroyed_items_size > 0
    error_message << "#{@undestroyed_items_size} blog post(s) failed to be destroyed" if @undestroyed_items_size > 0

    flash_success :now, error_message.join(", ")
    respond_to do |format|
      format.js
    end
  end
    
  protected
  
  def load_blog_posts
    search_options = {:offset => params[:start], :limit => params[:limit], :order => "created_at DESC"}
    search_options.merge!(:order => "#{params[:sort]} #{params[:dir]}") if params[:sort]
    
    if params[:blog_id]
      @blog = current_account.blogs.find(params[:blog_id])
      search_options.merge!(:conditions => ["blog_id=?", @blog.id])
    end

    query_params = params[:q]
    unless query_params.blank?
      query_params = query_params.split(/\s+/)
      query_params = query_params.map {|q| q+"*"}.join(" ")
    end
    
    @blog_posts = current_account.blog_posts.search(query_params, search_options.dup)
    @blog_posts_count = current_account.blog_posts.count_results(query_params)
  end
  
  def load_blog_post
    @blog_post = current_account.blog_posts.find(params[:id])
  end
  
  def load_blogs
    @blogs = current_account.blogs.find(:all, :order => "title ASC")
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
      :title => record.title,
      :author_name => record.author_name,
      :excerpt => (record.excerpt||"")[0..29],
      :body => (record.body||"")[0..29],
      :comments_count => record.comments.count,
      :unapproved_comments_count => record.unapproved_ham_comments_count,
      :author_id => record.author_id,
      :published_at => record.published_at ? record.published_at.to_s : "Draft",
      :created_at => record.created_at.to_s, 
      :spam_comments_count => record.spam_comments_count
    }
  end
  
  def json_response_for(record)
    json_response = truncate_record(record.reload)
    json_response.merge!(:flash => flash[:notice].to_s)
    json_response
  end

  def render_json_response
    errors = (@blog_post.errors.full_messages.blank? ? ($! ? $!.message : "")  : render_to_string(:partial => "/shared/error_messages_for", :locals => {:symbol => :blog_post})).to_s
    render :json => {:flash => flash[:notice].to_s, :close => @updated && @close, :errors => errors, 
                     :id => @blog_post.id, :success => @updated || @created }.to_json
  end
  
  def authorized?
    #index new create edit update destroy_collection
    if %w(edit update).index(self.action_name)
      return false unless current_user?
      return true if current_user.can?(:edit_blogs)
      self.load_blog_post
      return true if @blog_post.author_id == current_user.id
      return true if @blog_post.blog.created_by_id == current_user.id || @blog_post.blog.owner_id == current_user.id
    else
      return false unless current_user?
      return true if current_user.can?(:edit_blogs)
    end
    false
  end    
end
