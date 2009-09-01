#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class GroupsController < ApplicationController
  # check the authorized?
  required_permissions :none

  before_filter :load_group, :only => %w(show update destroy effective_permissions join leave)

  def async_get_name_id_hashes
    groups = current_account.groups.find :all, :order => "name"
    name_ids = []
    name_ids += [{ 'name' => 'New Group', 'id' => params[:with_new_group] }] if params[:with_new_group]  
    name_ids += groups.collect { |group| { 'name' => group.name, 'id' =>  group.id } }
    
    wrapper = {'total' => name_ids.size, 'collection' => name_ids}
    render :json => wrapper.to_json, :status => 200
  end
  
  def async_add_parties_or_create
    group = current_account.groups.find :first, :conditions => ["name = ?", params[:name]]
    ids = params[:ids].split(',').collect! { |id| id.to_i }
    nonexistent_party_ids = []
    
    # The user wishes to make a Group
    if group.nil?
      group = current_account.groups.build
      group.created_by = group.updated_by = current_user
      group.name = params[:name]
      unless group.save
        render :text => group.errors.full_messages #"Could not create Group '#{params[:name]}'"
        return
      end
    end
    
    
    ids.each do |id|
      begin # There is a chance a nonexistent ID will be passed
        party = Party.find id
        party.groups << group
      rescue ActiveRecord::RecordNotFound # A nonexistent ID was passed
        nonexistent_party_ids.push id
        next
      end
    end
    
    render :text => groups_path.to_json
  end
  
  def index
    respond_to do |format|
      format.html do
        @pager = ::Paginator.new(current_account.groups.count, ItemsPerPage) do |offset, limit|
          current_account.groups.find(:all, :order => "name", :limit => limit, :offset => offset)
        end

        @page = @pager.page(params[:page])
        @groups = @page.items
      end
      format.js
      format.json do
        render :json => build_group_collection_tree_panel_hashes.to_json
      end
    end
  end

  def show
  end

  def new
    @group = current_account.groups.build
  end

  def create
    params[:group][:party_ids] = params[:parties] if params[:parties]
    @group = current_account.groups.build(params[:group])
    @group.created_by = @group.updated_by = current_user
    @group.private = false unless params[:group][:private]
    @created = @group.save
    respond_to do |format|
      format.html do
        if @created then
          flash_success "Group saved"
          if params[:parties] 
            redirect_to edit_group_path(@group)
          else
            redirect_to groups_path
          end 
        else
          load_available_parties_and_permissions
          render :action => :new
        end
      end
      format.js do
        return render_json_response
      end
    end
  end

  def edit
    @formatted_selected_permissions_path = formatted_permission_grants_path(:format => "json", :assignee_type => "Group", :assignee_id => @group.id, :include_selected => true)
    @permission_grants_path = permission_grants_path(:assignee_type => "Group", :assignee_id => @group.id)
    @destroy_collection_permission_grants_path = destroy_collection_permission_grants_path(:assignee_type => "Group", :assignee_id => @group.id)

    @formatted_permission_denials_path = formatted_permission_denials_path(:assignee_id => @group.id, :assignee_type => "Group", :format => "json")
    @permission_denials_path = permission_denials_path(:assignee_type => "Group", :assignee_id => @group.id)
    @destroy_collection_permission_denials_path = destroy_collection_permission_denials_path(:assignee_type => "Group", :assignee_id => @group.id)

    @current_user_can_edit_party_security = current_user.can?(:edit_party_security)

    respond_to do |format|
      format.html
      format.js
    end
  end

  def update
    Group.transaction do

      @group.attributes = params[:group]
      @group.updated_by = current_user
      @updated = @group.save
      if @updated then
        flash_success :now, "Group updated"      
        respond_to do |format|
          format.html { redirect_to groups_path }
          format.js { render :json => {:success => true, :flash => flash[:notice].to_s}.to_json}
        end
      else
        respond_to do |format|
          format.html {render :action => :edit}
          format.js do
            @group_id = true
            return render_json_response
          end
        end
      end
    end
  end

  def destroy
    if @group.destroy
      flash_success "#{@group.name} successfully deleted"
      redirect_to groups_path
    end
  end
  
  def destroy_collection
    destroyed_items_size = 0
    current_account.groups.find(params[:ids].split(",").map(&:strip)).to_a.each do |group|
       destroyed_items_size += 1 if group.destroy
    end
    message = "#{destroyed_items_size} group(s) successfully deleted"
    success = destroyed_items_size > 0 ? true : false
    respond_to do |format|
      format.js do
        render :json => {:success => success, :flash => message}.to_json
      end
    end
  end
  
  def reorder
    source = current_account.groups.find(params[:id])
    if params[:type] == "append"
      target = current_account.groups.find(params[:target_id])
    else
      target = current_account.groups.find(params[:target_id]).parent
    end
    source.parent = target
    saved = source.save
    
    respond_to do |format|
      format.js do
        render :json => {:success => saved, :flash => saved ? "Group '#{source.label}' has been moved" : source.errors.full_messages}
      end
    end
  end

  def effective_permissions
    effective_permissions = @group.effective_permissions
    effective_permissions_count = @group.effective_permissions.size
    respond_to do |format|
      format.json do
        render :json => {:collection => effective_permissions.map{|p| {:name => p.name.humanize, :id => p.id}}, :total => effective_permissions_count }.to_json
      end
    end
  end
  
  def join
    self.load_party
    @exist = @party.groups.find_by_id(@group.id)
    @party.groups << @group if @exist.blank?
    @party.update_effective_permissions = true
    @party.save!
    respond_to do |format|
      format.html do
        if @exist.blank?
          return redirect_to(params[:next]) if params[:next]
        else
          return redirect_to(params[:return_to]) if params[:return_to]
        end
        redirect_to :back
      end
      format.js do
        render :json => {:success => true}.to_json
      end
    end
  end
  
  def leave
    self.load_party
    @exist = @party.groups.find_by_id(@group.id)
    @party.groups.delete(@group) if @exist
    @party.update_effective_permissions = true
    @party.save!
    respond_to do |format|
      format.html do
        if @exist
          return redirect_to(params[:next]) if params[:next]
        else
          return redirect_to(params[:return_to]) if params[:return_to]
        end
        redirect_to :back
      end
      format.js do
        render :json => {:success => true}.to_json
      end
    end
  end

  protected
  def load_group
    @group = current_account.groups.find(params[:id])
  end
  
  def load_party
    @party = current_account.parties.find(params[:party_id])
  end
  
  def build_group_collection_tree_panel_hashes
    out = []
    party = nil
    party = current_account.parties.find(:first, :conditions => ["id=?",params[:party_id]]) if params[:party_id]
    root_groups = current_account.groups.find(:all, :conditions => "parent_id IS NULL", :order => "name")
    root_groups.each do |root_group|
      out << assemble_record_tree_panel_hash(root_group, party)
    end
    out
  end
  
  def assemble_record_tree_panel_hash(record, party=nil)
    hash = {:id => record.id, :text => "#{record.name}  |  #{record.label}"}
    if party
      hash.merge!(:checked => true) if party.member_of?(record)
    end
    if record.children.count > 0
      children_hashes = []
      record.children.find(:all, :order => "name").each do |record_child|
        children_hashes << assemble_record_tree_panel_hash(record_child, party)
      end
      hash.merge!(:children => children_hashes)
    else
      hash.merge!(:children => [], :expanded => true)
    end
    hash
  end

  def render_json_response
    errors = (@group.errors.full_messages.blank? ? ($! ? $!.message : "")  : render_to_string(:partial => "/shared/error_messages_for", :locals => {:symbol => :group})).to_s
    render :json => {:flash => flash[:notice].to_s, :close => @updated && @close, :errors => errors, 
                     :id => @group.id, :success => @updated || @created }.to_json
  end    
  
  def authorized?
    if %w(index).index(self.action_name)
      return true
    elsif %w(edit join leave).index(self.action_name)
      return false unless current_user?
      self.load_group
      return true if current_user.can?(:edit_groups)
      return true if @group.created_by_id == current_user.id
    else
      return false unless current_user?
      return true if current_user.can?(:edit_groups)
    end
    false
  end
end
