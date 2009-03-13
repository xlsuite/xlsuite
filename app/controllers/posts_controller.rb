#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class PostsController < ApplicationController
  layout "forums-two-columns"

  required_permissions :none # checked manually later
  skip_before_filter :login_required, :only => %w(index show)

  before_filter :find_forum_category
  before_filter :find_forum
  before_filter :find_topic
  before_filter :find_post, :except => %w(index new create)
  before_filter :check_read_authorization, :only => %w(show)
  before_filter :check_write_authorization, :only => %w(new create edit update destroy)

  def index
    unless params[:forum_id].blank? then
      @forum = current_account.forums.find(params[:forum_id])
      return render(:missing) unless @forum.readable_by?(current_user? ? current_user : nil)
    end

    conditions, values = [], {}

    [:user_id, :topic_id, :forum_id, :forum_category_id].each do |attr|
      next if params[attr].blank?
      conditions << "forum_posts.#{attr} = :#{attr}"
      values[attr] = params[attr]
    end

    unless params[:q].blank?
      conditions << 'LOWER(forum_posts.body) LIKE :q'
      values[:q] = "%#{params[:q]}%"
    end

    conds = conditions.any? ? conditions.collect { |c| "(#{c})" }.join(' AND ') : nil
    conds = [conds, values] if conds
    @pager = ::Paginator.new(current_account.forum_posts.count(:conditions =>  conds), ItemsPerPage) do |offset, per_page|
      current_account.forum_posts.find(:all, :conditions => conds, 
          :select => "forum_posts.*, forums.name forum_name, forum_topics.title topic_title",
          :joins => "INNER JOIN forum_topics ON forum_topics.id = forum_posts.topic_id INNER JOIN forums ON forums.id = forum_posts.forum_id",
          :order => 'forum_posts.created_at desc, forum_posts.id desc',
          :limit => per_page, :offset => offset)
    end

    @page = @pager.page(params[:page])
    @posts = @page.items.select do |post|
      post.forum.readable_by?(current_user? ? current_user : nil)
    end

    render_posts_or_xml
  end

  def show
  end

  def new
    @post = ForumPost.new
    render_within_public_layout
  end

  def create
    if @topic.locked?
      flash[:notice] = 'This topic is locked.'
      return redirect_to(forum_category_forum_topic_path(:forum_category_id => params[:forum_category_id], :forum_id => params[:forum_id], :id => params[:topic_id]))
    end

    @post = current_account.forum_posts.build(params[:post])
    @post.topic = @topic
    @post.forum = @forum
    @post.forum_category = @forum_category
    @post.user = current_user
    @post.save!

    page_to_go = get_last_page
    page_to_go = "1" if params[:sort] =~ /newest/i    
    redirect_to forum_category_forum_topic_path(:forum_category_id => @forum_category.id, :forum_id => @forum.id, :id => @topic.id, 
      :anchor => @post.dom_id, :page => page_to_go, :show => params[:show] || "10", :sort => params[:sort])

    rescue ActiveRecord::RecordInvalid
      flash[:bad_reply] = 'Please post something at least...'
      redirect_to forum_category_forum_topic_path(:forum_category_id => params[:forum_category_id], :forum_id => params[:forum_id], :id => params[:topic_id], 
        :anchor => 'reply-form', :show => params[:show] || "10", :page => page_to_go, :sort => params[:sort])
  end
  
  def edit
    respond_to do |format| 
      format.html { render_within_public_layout }
      format.js
    end
  end
  
  def update
   @post.attributes = params[:post]
   @post.save!

   respond_to do |format|
     format.html do
       redirect_to forum_category_forum_topic_path(:forum_category_id => params[:forum_category_id], :forum_id => params[:forum_id], 
           :id => params[:topic_id], :anchor => @post.dom_id, 
           :page => params[:page], :show => params[:show], :sort => params[:sort] )
     end
     format.js 
   end
  end

  def destroy
    @post.destroy
    flash[:notice] = "ForumPost of '#{CGI::escapeHTML @post.topic.title}' was deleted."
    # check for posts_count == 1 because it's cached and counting the currently deleted post
    @post.topic.destroy and redirect_to forum_categories_url if @post.topic.posts_count == 1
    last_page = get_last_page
    page_to_go = (params[:page] || 1).to_i
    page_to_go = last_page if page_to_go > last_page
    redirect_to forum_category_forum_topic_path(:forum_category_id => params[:forum_category_id], :forum_id => params[:forum_id], :id => params[:topic_id], 
      :page => page_to_go, :show => params[:show], :sort => params[:sort]) unless performed?
  end
  
  protected
  def find_forum_category
    @forum_category = current_account.forum_categories.find(params[:forum_category_id]) unless params[:forum_category_id].blank?
  end

  def find_forum
    @forum = @forum_category.forums.find(params[:forum_id]) unless params[:forum_id].blank?
  end

  def find_topic
    @topic = @forum.topics.find(params[:topic_id]) unless params[:topic_id].blank?
  end

  def find_post
    if @topic then
      @post = @topic.posts.find(params[:id])
    else
      @post = current_account.forum_posts.find(params[:id])
      @topic = @post.topic
      @forum = @post.forum
      @forum_category = @post.forum_category
    end unless params[:id].blank?
  end

  def check_read_authorization
    return if @post.forum.readable_by?(current_user? ? current_user : nil) && @post.forum.forum_category.readable_by?(current_user? ? current_user : nil)
    access_denied
  end

  def check_write_authorization
    return access_denied unless current_user?
    editable = @post ? @post.editable_by?(current_user) : true
    root = [@post, @topic, @forum, @forum_category].compact.first
    root = root.forum if root.respond_to?(:forum)
    writeable = root.writeable_by?(current_user)
    return access_denied unless editable && writeable
  end

  def render_posts_or_xml
    respond_to do |format|
      format.html { render_within_public_layout }
      format.atom do
        render :action => "#{action_name}.rxml", :layout => false
      end
    end
  end

  def get_last_page
    posts_count = @post.topic.posts.find(:all).size
    items_per_page = params[:show] || "10"
    items_per_page = posts_count if params[:show] =~ /all/i
    items_per_page = items_per_page.to_i
    last_page = posts_count.to_f / items_per_page
    last_page = last_page.ceil.to_i
    return last_page
  end
end
