#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Public::GroupsController < ApplicationController
  # check the authorized?
  required_permissions :none

  before_filter :load_group, :only => %w(show update destroy join leave)
  before_filter :load_party, :only => %w(create update)

  def create
    begin
      @group = current_account.groups.build(params[:group])
      @group.private = false
      @group.created_by = @group.updated_by = @party
      @group.save!
      
      unless params[:join].blank?
        @party.groups << @group
        @party.update_effective_permissions = true
        @party.save!
      end
      
      respond_to do |format|
        format.html do
          flash_success params[:success_message] || "Group #{@group.label} successfully created"
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
    Group.transaction do

      @group.attributes = params[:group]
      @group.updated_by = @party
      @group.save!
      if @updated then
        flash_success :now, "Group updated"      
        respond_to do |format|
          format.html { return redirect_to_next_or_back_or_home }
          format.js { render :json => {:success => true, :flash => flash[:notice].to_s}.to_json}
        end
      else
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
  end
  
  def destroy
    @destroyed = @group.destroy
    if @destroyed
      flash_success params[:success_message] || "Group #{@group.label} successfully destroyed"
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
  
  def join
    if @group.public?
      self.load_party
      @exist = @party.groups.find_by_id(@group.id)
      @party.groups << @group if @exist.blank?
      @party.update_effective_permissions = true
      @party.save!
      respond_to do |format|
        format.html do
          if @exist.blank?
            flash_success "Successfully joined group #{@group.name}"
            return redirect_to(params[:next]) if params[:next]
          else
            flash_failure "You are already a member of #{@group.name}"
            return redirect_to(params[:return_to]) if params[:return_to]
          end
          redirect_to :back
        end
        format.js do
          render :json => {:success => true}.to_json
        end
      end
    else
      flash_failure "Cannot join group: #{@group.name} is a private group."
      respond_to do |format|
        format.html do
          redirect_to_return_to_or_back_or_home
        end
        format.js do
          render :json => {:success => false, :errors => flash_messages_to_s}
        end
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
          flash_success "Successfully left group #{@group.name}"
          return redirect_to(params[:next]) if params[:next]
        else
          flash_failure "Could not leave group: You do not belong to #{@group.name}"
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
    self.load_profile
    @party = @profile ? @profile.party : current_user
  end
  
  def load_profile    
    @profile = current_account.profiles.find(params[:profile_id]) if(params[:profile_id] && !params[:profile_id].blank?)
  end
  
  def authorized?
    return false unless current_user?
    return true if current_user.can?(:edit_groups)
    self.load_party
    return false unless @profile.writeable_by?(current_user) if @profile
    if %w(update destroy).index(self.action_name)
      self.load_group
      return true if @group.created_by_id == @party.id
    elsif %w(join leave).index(self.action_name)
      self.load_group
      return true
    elsif %w(create).index(self.action_name)
      return true         
    end
    false
  end
end
