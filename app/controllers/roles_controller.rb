#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class RolesController < ApplicationController
  required_permissions :edit_roles

  before_filter :load_role, :only => %w(show edit update destroy effective_permissions)
  before_filter :load_available_roles_and_permissions, :only => %w(new edit)

  def index
    respond_to do |format|
      format.html do
        @pager = ::Paginator.new(current_account.roles.count(:conditions => "type IS NULL"), ItemsPerPage) do |offset, limit|
          current_account.roles.find(:all, :conditions => "type IS NULL", :order => "name", :limit => limit, :offset => offset)
        end

        @page = @pager.page(params[:page])
        @roles = @page.items      
      end
      format.json do
        render :json => build_role_collection_tree_panel_hashes.to_json
      end
      format.js
    end
  end

  def show
  end

  def new
    @role = Role.new
  end

  def create
    @role = current_account.roles.build(params[:role])
    @role.created_by = @role.updated_by = current_user
    @created = @role.save
    respond_to do |format|
      format.html do
        if @role.save then
          flash_success "Role saved"
          redirect_to roles_path
        else
          render :action => :new
        end      
      end
      format.js do
        return render_json_response
      end
    end
  end

  def edit
    @formatted_selected_permissions_path = formatted_permission_grants_path(:format => "json", :assignee_type => "Role", :assignee_id => @role.id, :include_selected => true)
    @permission_grants_path = permission_grants_path(:assignee_type => "Role", :assignee_id => @role.id)
    @destroy_collection_permission_grants_path = destroy_collection_permission_grants_path(:assignee_type => "Role", :assignee_id => @role.id)

    @formatted_permission_denials_path = formatted_permission_denials_path(:assignee_id => @role.id, :assignee_type => "Role", :format => "json")
    @permission_denials_path = permission_denials_path(:assignee_type => "Role", :assignee_id => @role.id)
    @destroy_collection_permission_denials_path = destroy_collection_permission_denials_path(:assignee_type => "Role", :assignee_id => @role.id)
    
    @current_user_can_edit_party_security = current_user.can?(:edit_party_security)

    respond_to do |format|
      format.html
      format.js
    end
  end

  def update
    Role.transaction do
      @role.attributes = params[:role]
      @role.updated_by = current_user
      if @role.save! then
        flash_success "Role saved"
        respond_to do |format|
          format.html { redirect_to roles_path }
          format.js
        end
        
      else
        render :action => :edit
      end
    end
  end

  def destroy
    @role.destroy
    redirect_to roles_path
  end

  def destroy_collection
    destroyed_items_size = 0
    current_account.roles.find(params[:ids].split(",").map(&:strip)).to_a.each do |role|
       destroyed_items_size += 1 if role.destroy
    end
    message = "#{destroyed_items_size} role(s) successfully deleted"
    success = destroyed_items_size > 0 ? true : false
    respond_to do |format|
      format.js do
        render :json => {:success => success, :flash => message}.to_json
      end
    end
  end
  
  def effective_permissions
    effective_permissions = @role.effective_permissions
    effective_permissions_count = @role.effective_permissions.size
    respond_to do |format|
      format.json do
        render :json => {:collection => effective_permissions.map{|p| {:name => p.name.humanize, :id => p.id}}, :total => effective_permissions_count }.to_json
      end
    end
  end
  
  protected
  def load_role
    @role = current_account.roles.find(params[:id])
  end

  def load_available_roles_and_permissions
    @available_roles = if @role then
      current_account.roles.find(:all, :conditions => ["id NOT IN (?)", @role], :order => "name")
    else
      current_account.roles.find(:all, :order => "name")
    end
    @available_permissions = Permission.find(:all, :order => "name")
  end

  def build_role_collection_tree_panel_hashes
    out = []
    object = nil
    if params[:party_id]
      object = current_account.parties.find(:first, :conditions => ["id=?",params[:party_id]]) if params[:party_id]
    elsif params[:group_id]
      object = current_account.groups.find(:first, :conditions => ["id=?",params[:group_id]]) if params[:group_id]
    end
    root_roles = current_account.roles.find(:all, :conditions => "parent_id IS NULL", :order => "name")
    root_roles.each do |root_role|
      out << assemble_record_tree_panel_hash(root_role, object)
    end
    out
  end
  
  def assemble_record_tree_panel_hash(record, object=nil)
    hash = {:id => record.id, :text => record.name}
    if object
      hash.merge!(:checked => true) if object.member_of?(record)
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

  def render_json_response
    errors = (@role.errors.full_messages.blank? ? ($! ? $!.message : "")  : render_to_string(:partial => "/shared/error_messages_for", :locals => {:symbol => :role})).to_s
    render :json => {:flash => flash[:notice].to_s, :close => @updated && @close, :errors => errors, 
                     :id => @role.id, :success => @updated || @created }.to_json
  end    
end
