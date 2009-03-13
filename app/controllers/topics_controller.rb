#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class TopicsController < ApplicationController
  layout "forums-two-columns"
  
  required_permissions :none # checked manually later
  skip_before_filter :login_required, :only => %w(show)

  before_filter :find_forum_category
  before_filter :find_forum
  before_filter :find_topic, :except => %w(index new create)
  before_filter :initialize_topic, :only=> %w(new create)

  before_filter :check_read_authorization, :only => %w(show)
  before_filter :check_write_authorization, :only => %w(new create edit update destroy)

  def new
    @topic = ForumTopic.new
    render_within_public_layout
  end

  def edit
    @forum_categories = current_account.forum_categories.find(:all, :order => "name ASC")
    render_within_public_layout
  end

  def show
    @title = [@topic.title, "Forums"]
    (session[:topics] ||= {})[@topic.id] = Time.now.utc if current_user?
    @topic.hit! unless current_user? and @topic.user == current_user

    items_per_page = params[:show] || ItemsPerPage
    items_per_page = @topic.posts.count if params[:show] =~ /all/i
    items_per_page = items_per_page.to_i

    order_mode = "ASC"
    if params[:sort] =~ /newest/i
      order_mode = "DESC"
    elsif params[:sort] =~ /oldest/i
      order_mode = "ASC"
    end

    @pager = ::Paginator.new(@topic.posts.count, items_per_page) do |offset, limit|
      @topic.posts.find(:all, :order => "forum_posts.created_at #{order_mode}", :limit => limit, :offset => offset)
    end

    @page = @pager.page(params[:page])
    @posts = @page.items
    @voices = @topic.voices
    render_within_public_layout
  end

  def create
    ForumTopic.transaction do
      @topic  = @forum.topics.build(params[:topic])
      assign_protected
      @topic.forum_category_id = @forum_category.id
      @topic.save!
      @post   = @topic.posts.build(params[:topic])
      @post.forum_id = @forum.id
      @post.forum_category_id = @forum_category.id
      @post.user = current_user
      @post.save!
    end
    flash[:notice] = "#{@topic.title} successfully created" 
    return redirect_to(params[:return_to]) unless params[:return_to].blank?
    redirect_to forum_category_forum_topic_url(@forum_category, @forum, @topic)
    rescue ActiveRecord::RecordInvalid => e
      flash[:notice] = e.to_s
      redirect_to forum_categories_url
  end

  def update
    @topic.attributes = params[:topic]
    @topic.forum_id = params[:topic][:forum_id]
    @topic.forum_category_id = params[:topic][:forum_category_id]
    assign_protected
    if !@topic.save
      flash[:notice] = @topic.errors.full_messages
      redirect_to edit_forum_category_forum_topic_path(:forum_category_id => @topic.forum_category_id, :forum_id => @topic.forum_id, :id => @topic.id)
    else
      flash[:notice] = "#{@topic.title} successfully updated"
      redirect_to forum_category_forum_topic_path(:forum_category_id => @topic.forum_category_id, :forum_id => @topic.forum_id, :id => @topic.id, :page => params[:page], :show => params[:show])
    end
  end

  def destroy
    @topic.destroy
    flash[:notice] = "Topic '#{CGI::escapeHTML @topic.title}' was deleted."
    redirect_to forum_categories_url
  end

  protected
  def assign_protected
    @topic.account = current_account
    @topic.user     = current_user if @topic.new_record?
    # admins and moderators can sticky and lock topics
    return unless current_user.can?(:admin_forum)
    @topic.sticky, @topic.locked = params[:topic][:sticky], params[:topic][:locked] 
    # only admins can move
    return unless current_user.can?(:admin_forum)
  end

  def find_forum_category
    @forum_category = current_account.forum_categories.find(params[:forum_category_id])
  end

  def find_forum
    @forum = @forum_category.forums.find(params[:forum_id])
  end

  def find_topic
    @topic = @forum.topics.find(params[:id])
  end

  def initialize_topic
    @topic = @forum.topics.build
  end

  def check_read_authorization
    return if @forum.readable_by?(current_user? ? current_user : nil) && @forum.forum_category.readable_by?(current_user? ? current_user : nil)
    access_denied
  end

  def check_write_authorization
    return access_denied unless current_user?
    logger.debug {"==============> editable? #{@topic.editable_by?(current_user).inspect}, writeable? #{@topic.forum.writeable_by?(current_user).inspect}"}
    return access_denied unless @topic.editable_by?(current_user) && @topic.forum.writeable_by?(current_user) && @topic.forum.forum_category.writeable_by?(current_user)
  end
end
