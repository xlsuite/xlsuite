#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ForumCategoriesController < ApplicationController
  before_filter :find_or_initialize_forum_category, :except => %w(index)
  before_filter :load_available_groups, :only => %w(index new edit)
  

  skip_before_filter :login_required, :only => [:index, :show]
  required_permissions %w(new create edit update destroy) => :admin_forum
  
  before_filter :check_read_authorization, :only => %w(show)
  before_filter :check_write_authorization, :only => %w(edit update destroy)

  layout "forums-two-columns"

  def index
    @title = "Forums"
    @forum_categories = current_account.forum_categories.find(:all, :order => "name ASC").reject{|f| !f.readable_by?(current_user? ? current_user : nil)}
    render_within_public_layout
  end

  def new
    @forum = current_account.forum_categories.build
    render_within_public_layout
  end  

  def edit
    render_within_public_layout
  end

  def show
    @forums = @forum_category.forums
    render_within_public_layout
  end

  def create
    if @forum_category.update_attributes(params[:forum_category]) 
      flash[:notice] = "#{@forum_category.name} successfully created"
    else
      flash[:notice] = @forum_category.errors.full_messages
    end
    redirect_to forum_categories_path
  end

  def update
    if @forum_category.update_attributes(params[:forum_category]) 
      flash[:notice] = "#{@forum_category.name} successfully updated"
      redirect_to forum_categories_path
    else
      flash[:notice] = @forum_category.errors.full_messages
      redirect_to edit_forum_category_path(@forum_category)
    end
  end

  def destroy
    flash[:notice] = "#{@forum_category.name} destroyed" if @forum_category.destroy
    redirect_to forum_categories_url
  end

  protected
  def find_or_initialize_forum_category
    @forum_category = params[:id] ? current_account.forum_categories.find(params[:id]) : current_account.forum_categories.build
  end

  def load_available_groups
    @available_groups = current_account.groups.find(:all, :order => "name")
  end
  
  def check_read_authorization
    return if @forum_category.readable_by?(current_user? ? current_user : nil)
    access_denied
  end

  def check_write_authorization
    return access_denied unless current_user?
    return access_denied unless @forum_category.writeable_by?(current_user)
  end
end
