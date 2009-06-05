#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class CommentsController < ApplicationController
  TIMESTAMP_FORMAT = "%m/%d/%Y".freeze
  
  required_permissions :none
  before_filter :load_commentable, :except => %w(mark_as_ham mark_as_spam index destroy_collection approve_collection unapprove_collection)
  before_filter :load_comments, :only => %w(destroy_collection approve_collection unapprove_collection)
  before_filter :load_comment, :only => [:edit, :update]

  def index
    respond_to do |format|
      format.html
      format.js do
        @formatted_comments_path = formatted_comments_path(:format => :json)
        @edit_comment_path = edit_comment_path(:commentable_type => "__COM_TYPE__", :commentable_id => "__COM_ID__", :id => "__ID__")
      end
      format.json do
        load_index_comments
        render :json => {:collection => assemble_records(@comments), :total => @comments_count}.to_json
      end
    end
  end
  
  def new
    @comment = @commentable.comments.build
    respond_to do |format|
      format.js do
        @toolbar_url = comments_path(:commentable_type => @commentable.class.name, :commentable_id => @commentable.id)
        @toolbar_close_url = comments_path(:commentable_type => @commentable.class.name, :commentable_id => @commentable.id, :commit_type => "close")
        @toolbar_page_to_open_after_new_url = edit_comment_path(:commentable_type => @commentable.class.name, :commentable_id => @commentable.id, :id => "__ID__")
      end
    end
  end

  def create
    
    flash[:liquid] ||= {}
    flash[:liquid][:params] = params
    
    if current_domain.get_config(:require_login_for_comments) && !current_user?
      error_message = "You must be logged in to post a comment."
      respond_to do |format|
        format.html do
          flash_failure error_message
          redirect_to_return_to_or_back
        end
        format.js do
          render :json => {:flash => error_message, :errors => error_message, :success => false }.to_json
        end
      end
    else
      params[:comment] ||= {}
      params[:comment].merge!(:rating => params[:rating]) unless params[:rating].blank?
      @comment = current_account.comments.build(params[:comment])
      @comment.commentable = @commentable
      @comment.domain = current_domain
      
      @comment.user_agent = request.env["HTTP_USER_AGENT"]
      @comment.referrer_url = request.env["HTTP_REFERER"]
      @comment.request_ip = request.remote_ip
      @comment.created_by = @comment.updated_by = current_user if current_user?
      @created = @comment.save
      MethodCallbackFuture.create!(:models => [@comment], :account =>  @comment.account, :method => :do_spam_check!) if @created
      @close = true if params[:commit_type] && params[:commit_type] =~ /close/i
      respond_to do |format|
        format.html do
          unless @created
            flash_failure @comment.errors.full_messages
          else
            if @comment.reload.approved_at
              flash_success "Comment created"
            else
              flash_success params[:success_message] ? params[:success_message] : "Comment created"
            end
          end
          redirect_to_return_to_or_back
        end
        format.js do
          render_json_response
        end
      end
    end
  end
  
  def edit
    respond_to do |format|
      format.js do
        @formatted_flaggings_path = formatted_flaggings_path(:flaggable_type => @comment.class.name, :flaggable_id => @comment.id, :format => :json)
        @toolbar_url = comment_path(:commentable_type => @commentable.class.name, :commentable_id => @commentable.id, :id => @comment.id)
        @toolbar_close_url = comment_path(:commentable_type => @commentable.class.name, :commentable_id => @commentable.id, :id => @comment.id, :commit_type => "close")
        @toolbar_page_to_open_after_new_url = edit_comment_path(:commentable_type => @commentable.class.name, :commentable_id => @commentable.id, :id => "__ID__")
      end
    end
  end

  def update
    params[:comment] ||= {}
    params[:comment].merge!(params[:rating]) unless params[:rating].blank?
    @comment.attributes = params[:comment]
    @comment.approved_at = params[:approved] ? Time.now : nil
    @comment.updated_by = current_user if current_user?
    @updated = @comment.save
    @close = true if params[:commit_type] && params[:commit_type] =~ /close/i
    respond_to do |format|
      format.html do
        redirect_to_return_to_or_back
      end
      format.js do
        render_json_response
      end
    end
  end

  def destroy_collection
    @destroyed_items_size = 0
    @undestroyed_items_size = 0
    @comments.each do |comment|
      if comment.destroy
        @destroyed_items_size += 1
      else
        @undestroyed_items_size += 1
      end
    end
      
    error_message = []
    error_message << "#{@destroyed_items_size} comment(s) successfully deleted" if @destroyed_items_size > 0
    error_message << "#{@undestroyed_items_size} comment(s) failed to be destroyed" if @undestroyed_items_size > 0

    flash_success :now, error_message.join(", ")
    respond_to do |format|
      format.js
    end
  end
  
  def approve_collection
    @approved_items_size = 0
    @unapproved_items_size = 0
    @comments.each do |comment|
      comment.approved_at = Time.now
      if comment.save!
        @approved_items_size += 1
      else
        @unapproved_items_size += 1
      end
    end

    error_message = []
    error_message << "#{@approved_items_size} comment(s) successfully approved" if @approved_items_size > 0
    error_message << "#{@unapproved_items_size} comment(s) failed to be approved" if @unapproved_items_size > 0

    flash_success :now, error_message.join(", ")
    respond_to do |format|
      format.js
    end
  end
  
  def unapprove_collection
    @unapproved_items_size = 0
    @failed_items_size = 0
    @comments.each do |comment|
      comment.approved_at = nil
      if comment.save!
        @unapproved_items_size += 1
      else
        @failed_items_size += 1
      end
    end

    error_message = []
    error_message << "#{@unapproved_items_size} comment(s) successfully unapproved" if @unapproved_items_size > 0
    error_message << "#{@failed_items_size} comment(s) failed to be unapproved" if @failed_items_size > 0

    flash_success :now, error_message.join(", ")
    respond_to do |format|
      format.js
    end
  end
  
  def mark_as_spam
    count = 0
    current_account.comments.find(params[:ids].split(",").map(&:strip).reject(&:blank?)).to_a.each do |comment|
      comment.confirm_as_spam!
      count += 1
    end
    flash_success :now, "#{count} comment(s) successfully marked as spam"
    render :update do |page|
      page << refresh_grid_datastore_of("comments")
      page << update_notices_using_ajax_response
    end
  end
  
  def mark_as_ham
    count = 0
    current_account.comments.find(params[:ids].split(",").map(&:strip).reject(&:blank?)).to_a.each do |comment|
      comment.confirm_as_ham!
      comment.update_attribute("approved_at", Time.now.utc) if params[:approve]
      count += 1
    end
    flash_success :now, "#{count} comment(s) successfully marked as ham"
    render :update do |page|
      page << refresh_grid_datastore_of("comments")
      page << update_notices_using_ajax_response
    end
  end

  protected

  def load_comments
    @comments = []
    self.load_commentable
    if @commentable
      @comments = @commentable.comments.find(params[:ids].split(",").map(&:strip).reject(&:blank?))
    elsif params[:commentable_types] && params[:commentable_ids]
      com_ids = params[:commentable_ids].split(",").map(&:strip).reject(&:blank?)
      ids = params[:ids].split(",").map(&:strip).reject(&:blank?)
      params[:commentable_types].split(",").map(&:strip).reject(&:blank?).each_with_index do |type, i|
        commentable = current_account.send(type.classify.underscore.pluralize).find(com_ids[i])
        @comments << commentable.comments.find(ids[i]) if commentable
      end
    else
      @comments = current_account.find(params[:ids].split(",").map(&:strip).reject(&:blank?))
    end
  end

  def load_commentable
    if params[:commentable_type] && params[:commentable_id]
      @commentable = current_account.send(params[:commentable_type].classify.underscore.pluralize).find(params[:commentable_id])
    end
  end
  
  def load_comment
    @comment = @commentable.comments.find(params[:id])
  end

  def assemble_records(records)
    results = []
    records.each do |record|
      results << truncate_record(record)
    end
    results
  end

  def truncate_record(record)
    commentable = record.commentable
    commentable_info = case commentable
    when Listing
      [commentable.quick_description, edit_listing_path(commentable)]
    when Product
      [commentable.name, edit_product_path(commentable) ]
    when Profile
      ["#{commentable.full_name}, #{commentable.company_name}", commentable.party ? edit_profile_path(commentable.party) : ""]
    when BlogPost
      [commentable.title, edit_blog_post_path(commentable)]
    else
      [commentable ? commentable.dom_id : "Unknown", ""]
    end

    {
      :id => record.id,
      :name => record.name,
      :url => record.url,
      :email => record.email,
      :approved_at => record.approved_at ? record.approved_at.strftime(TIMESTAMP_FORMAT) : "",
      :created_at => record.created_at.strftime(TIMESTAMP_FORMAT),
      :referrer_url => record.referrer_url,
      :body => (ERB::Util.html_escape(record.body)||"")[0..50],
      :user_agent => record.user_agent,
      :commentable_type => record.commentable_type,
      :commentable_id => record.commentable_id,
      :commentable_description => commentable_info.first,
      :commentable_path => commentable_info.last,
      :flaggings => "#{record.approved_flaggings_count} / #{record.unapproved_flaggings_count}"
    }
  end

  def load_index_comments
    conditions = params[:spam] =~ /true/i ? ["spam is true"] : ["spam is false"]

    search_options = {:offset => params[:start], :limit => params[:limit], :order => "created_at DESC"}
    search_options.merge!(:order => "#{params[:sort]} #{params[:dir]}") if params[:sort]

    if params[:commentable_type] && params[:commentable_id]
      self.load_commentable
      conditions = conditions << ["commentable_type=? AND commentable_id=?"]
      search_options.merge!(:conditions => [conditions.join(" AND "), @commentable.class.name, @commentable.id])
    elsif params[:commentable_type]
      conditions = conditions << ["commentable_type=? "]
      search_options.merge!(:conditions => [conditions.join(" AND "), params[:commentable_type]])
    else
      conditions << "commentable_type != 'Party'"
      search_options.merge!(:conditions => conditions.join(" AND "))
    end

    query_params = params[:q]
    unless query_params.blank?
      query_params = query_params.split(/\s+/)
      query_params = query_params.map {|q| q+"*"}.join(" ")
    end

    @comments = current_account.comments.search(query_params, search_options)
    search_options.delete(:offset)
    search_options.delete(:limit)
    @comments_count = current_account.comments.count_results(query_params, search_options)
  end

  def json_response_for(record)
    json_response = truncate_record(record.reload)
    json_response.merge!(:flash => flash[:notice].to_s)
    json_response
  end

  def render_json_response
    errors = (@comment.errors.full_messages.blank? ? ($! ? $!.message : "")  : render_to_string(:partial => "/shared/error_messages_for", :locals => {:symbol => :comment})).to_s
    render :json => {:flash => flash[:notice].to_s, :close => @updated && @close, :errors => errors,
                     :id => @comment.id, :success => @updated || @created }.to_json
  end
  
  def authorized?
    return true if current_user.can?(:edit_comments)
    if %w(new).include?(self.action_name)
      return self.current_user?
    elsif %w(create).include?(self.action_name)
      return true
    end
    false
  end   
end
