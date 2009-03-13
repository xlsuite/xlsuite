#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class PermissionGrantsController < ApplicationController
  required_permissions :edit_party_security
  before_filter :load_assignee

  def index
    respond_to do |format|
      format.json do
        permission_hashes, permissions_count = self.build_permission_hashes
        render :json => {:collection => permission_hashes, :total => permissions_count}.to_json
      end
    end
  end

  def create
    self.load_subjects
    PermissionGrant.create_collection_by_assignee_and_subjects(@assignee, @subjects)
    
    respond_to do |format|
      format.js { render :json => {:success => true}.to_json }
    end
  end
  
  def destroy_collection
    self.load_subjects
    destroyed_items_count = PermissionGrant.destroy_collection_by_assignee_and_subjects(@assignee, @subjects)
    success = destroyed_items_count == @subjects.size ? true : false
    respond_to do |format|
      format.js { render :json => {:success => success}.to_json }
    end
  end

  protected
  def build_permission_hashes
    out = []
    total_count = 0
    permissions = case params[:mode]
      when /total/i
        @assignee.total_granted_permissions.sort_by{|e| e.name}
      else
        @assignee.permissions
      end
    if params[:include_selected]
      selected_permission_ids = permissions.map(&:id)
      Permission.find(:all).each do |p|
        hash = self.assemble_record(p)
        hash.merge!(:selected => true) if selected_permission_ids.index(p.id)
        out << hash
      end
      total_count = Permission.count
    else
      permissions.each do |p|
        out << self.assemble_record(p)
      end
      total_count = @assignee.permissions.count
    end
    [out, total_count]
  end

  def load_assignee
    @assignee = current_account.send(params[:assignee_type].classify.underscore.pluralize).find(params[:assignee_id])
  end

  def assemble_record(record)
    {:id => record.id, :name => record.name.humanize}
  end

  def load_subjects
    @subjects = params[:subject_type].classify.constantize.find(params[:subject_ids].split(","))
  end
end
