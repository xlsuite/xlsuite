#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ForumsController < ApplicationController
  skip_before_filter :login_required, :only => [:show]
  required_permissions %w(new create edit update destroy) => :admin_forum

  before_filter :find_forum_category
  before_filter :find_forum, :only => %w(show edit update destroy)

  before_filter :check_read_authorization, :only => %w(show)
  before_filter :check_write_authorization, :only => %w(edit update destroy)

  before_filter :load_available_groups, :only => %w(index new edit)

  layout "forums-two-columns"

  def index
    @title = "Forums"
    @forums = @forum_category.forums.readable_by(current_user? ? current_user : nil)
    render_within_public_layout
  end

  def new
    @forum = Forum.new
    render_within_public_layout
  end

  def show
    @topics = @forum.topics.find(:all, :include => :replied_by_user,
        :order => 'sticky desc, replied_at desc')
    render_within_public_layout
  end

  def create
    Forum.transaction do
      @forum = current_account.forums.build(params[:forum])

      @forum.forum_category = @forum_category
      if @forum.save
        flash[:notice] = "#{@forum.name} successfully created"    
      else
        flash[:notice] = @forum.errors.full_messages
      end
      redirect_to forum_categories_url
    end
  end

  def edit
    render_within_public_layout
  end

  def update
    Forum.transaction do
      if @forum.update_attributes(params[:forum])
        flash[:notice] = "#{@forum.name} successfully updated"
      else
        flash[:notice] = @forum.errors.full_messages
      end
      redirect_to forum_categories_url
    end
  end

  def destroy
    @forum.destroy
    redirect_to forum_categories_url
  end

  protected
    def find_forum_category
    @forum_category = current_account.forum_categories.find(params[:forum_category_id])
  end  

  def find_forum
    @forum = @forum_category.forums.find(params[:id])
  end

  def load_available_groups
    @available_groups = current_account.groups.find(:all, :order => "name")
  end

  def check_read_authorization
    return if @forum.readable_by?(current_user? ? current_user : nil) && @forum.forum_category.readable_by?(current_user? ? current_user : nil)
    access_denied
  end

  def check_write_authorization
    return access_denied unless current_user?
    return access_denied unless @forum.writeable_by?(current_user)
  end
end
