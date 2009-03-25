#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Public::BlogsController < ApplicationController
  # check authorized?
  required_permissions :none
  
  before_filter :load_blog, :only => %w(update destroy)
  before_filter :load_party, :only => %w(create update)
  
  def create
    begin
      @blog = self.current_account.blogs.build(params[:blog])
      @blog.created_by = @blog.updated_by = @blog.owner = @party
      @blog.author_name = @party.display_name
      @blog.domain = self.current_domain
      @blog.save!
      respond_to do |format|
        format.html do
          flash_success params[:success_message] || "Blog #{@blog.label} successfully created"
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
  
  def update
    begin
      @blog.attributes=params[:blog]
      @blog.updated_by =  @party
      @blog.save!
      respond_to do |format|
        format.html do
          flash_success params[:success_message] || "Blog #{@blog.label} successfully updated"
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
    label = @blog.label
    @destroyed = @blog.destroy
    if @destroyed
      flash_success params[:success_message] || "Blog #{label} successfully destroyed"
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
  
  def validate_label
    @blog = current_account.blogs.build(:label => params[:label])
    @blog.valid? # We just want to run validation

    valid = false
    message = ""
    if @blog.errors.on(:label) then
      message = @blog.errors.on(:label) 
    else
      valid = true
    end
    respond_to do |format|
      format.js do
        render :json => {:success => true, :valid => valid, :message => message }
      end
    end
  end
  
  protected
  def load_blog
    @blog = current_account.blogs.find(params[:id])
  end
  
  def load_party
    self.load_profile
    @party = @profile ? @profile.party : current_user
  end
  
  def load_profile    
    @profile = current_account.profiles.find(params[:profile_id]) if(params[:profile_id] && !params[:profile_id].blank?)
  end
  
  def authorized?
    return true if %w(validate_label).index(self.action_name)
    return false unless current_user?
    return true if current_user.can?(:edit_blogs)
    self.load_party
    return false unless @profile.writeable_by?(current_user) if @profile
    if %w(update destroy).index(self.action_name)
      self.load_blog
      return true if @blog.created_by_id == @party.id || @blog.owner_id == @party.id
    elsif %w(create).index(self.action_name)
      return true
    end
    false
  end      
end
