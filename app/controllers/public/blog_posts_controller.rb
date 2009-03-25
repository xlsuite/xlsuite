#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Public::BlogPostsController < ApplicationController
  required_permissions :none
  
  before_filter :convert_link_to_absolute, :only => [:create, :update]
  before_filter :load_blogs, :only => [:new, :edit]
  before_filter :load_blog_post, :only => [:edit, :update, :destroy]
  before_filter :load_party, :only => %w( create update)
  
  def create
    begin
      publish = params[:blog_post].delete(:publish)
      @blog_post = current_account.blog_posts.build(params[:blog_post])
      if publish
        @blog_post.published_at = Time.now
      end
      @blog = self.current_account.blogs.find(params[:blog_id])
      @blog_post.blog = @blog
      @blog_post.current_domain = self.current_domain
      @blog_post.domain = self.current_domain
      @blog_post.author = @party
      @blog_post.hide_comments = params[:blog_post][:hide_comments] ? true : false
      @blog_post.save!
      flash_success params[:success_message] || "Blog post for #{@blog.label} blog successfully created"    
      respond_to do |format|
        format.html do
          params[:next]=params[:next].gsub(/__id__/i, @blog_post.id.to_s).gsub(/__blog_id__/i, @blog_post.blog.id.to_s) if params[:next]
          return redirect_to_next_or_back_or_home
        end
        format.js do
          render :json => {:success => true, :message => flash[:notice].to_s}
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
      publish = params[:blog_post].delete(:publish)
  
      @blog_post.attributes = params[:blog_post]
      @blog_post.editor = @party
      if(!@blog_post.published_at && publish)
        @blog_post.published_at = Time.now
      elsif(@blog_post.published_at && !publish)
        @blog_post.published_at = nil
      end
      @blog_post.deactivate_commenting_on = nil if params[:blog_post][:deactivate_commenting_on].blank?
      @blog_post.hide_comments = nil unless params[:blog_post][:hide_comments]
      @blog_post.save!
      respond_to do |format|
        format.html do
          flash_success params[:success_message] || "Blog post successfully updated"  
          params[:next]=params[:next].gsub(/__id__/i, @blog_post.id.to_s).gsub(/__blog_id__/i, @blog_post.blog.id.to_s) if params[:next]
          return redirect_to_next_or_back_or_home
        end
        format.js do
          render :json => {:success => true}
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
    @destroyed = @blog_post.destroy
    if @destroyed
      flash_success params[:success_message] || "Post #{@blog_post.permalink} successfully destroyed"
    else
      errors = $!.message.to_s
      flash_failure errors
    end
    respond_to do |format|
      format.html do
        return @destroyed ? redirect_to_next_or_back_or_home : redirect_to_return_to_or_back_or_home
      end
      format.js do
        render :json => {:success => true, :errors => [errors]}
      end
    end
  end
  
  protected
  def load_blog_post
    @blog_post = current_account.blog_posts.find(params[:id])
  end
  
  def load_blogs
    @blogs = current_account.blogs.find(:all, :order => "title ASC")
  end
  
  def load_party
    self.load_profile
    @party = @profile ? @profile.party : current_user
  end
  
  def load_profile    
    @profile = current_account.profiles.find(params[:profile_id]) if(params[:profile_id] && !params[:profile_id].blank?)
  end
  
  def convert_link_to_absolute
    if params[:blog_post] && !params[:blog_post][:link].blank? && !(params[:blog_post][:link] =~ /http:\/\//)
      params[:blog_post][:link] = "http://" + params[:blog_post][:link]
    end
  end
  
  def authorized?
    return false unless current_user?
    return true if current_user.can?(:edit_blogs)
    self.load_party
    return false unless @profile.writeable_by?(current_user) if @profile
    if %w(update destroy).index(self.action_name)
      self.load_blog_post
      return true if @blog_post.author_id == @party.id
      return true if @blog_post.blog.created_by_id == @party.id || @blog_post.blog.owner_id == @party.id
    elsif %w(create).index(self.action_name)
      return true
    end
    false
  end    
end
