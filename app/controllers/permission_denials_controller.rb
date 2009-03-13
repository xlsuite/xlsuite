#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class PermissionDenialsController < ApplicationController
  required_permissions :edit_party_security
  before_filter :load_assignee

  def index
    respond_to do |format|
      format.json do
        denied_permissions = self.build_denied_permission_hashes
        render :json => {:collection => denied_permissions, :total => denied_permissions.size}.to_json
      end
    end
  end
  
  def create
    self.load_subjects
    PermissionDenial.create_collection_by_assignee_and_subjects(@assignee, @subjects)
    
    respond_to do |format|
      format.js { render :json => {:success => true}.to_json }
    end
  end
  
  def destroy_collection
    self.load_subjects
    destroyed_items_count = PermissionDenial.destroy_collection_by_assignee_and_subjects(@assignee, @subjects)
    success = destroyed_items_count == @subjects.size ? true : false
    respond_to do |format|
      format.js { render :json => {:success => success}.to_json }
    end
  end

  protected
  def build_denied_permission_hashes
    denied_permission_ids = @assignee.denied_permissions.map(&:id)
    all_permissions = Permission.find(:all, :order => "name")
    permissions = []
    all_permissions.each do |p|
      hash = {:id => p.id, :name => p.name.humanize}
      hash.merge!(:checked => true) if denied_permission_ids.index(p.id)
      permissions << hash
    end
    permissions
  end

  def load_assignee
    @assignee = current_account.send(params[:assignee_type].classify.underscore.pluralize).find(params[:assignee_id])
  end
  
  def load_subjects
    @subjects = params[:subject_type].classify.constantize.find(params[:subject_ids].split(","))
  end
end
