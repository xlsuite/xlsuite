#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class WorkflowsController < ApplicationController
  required_permissions %w(index create edit update destroy destroy_collection) => :edit_workflows
  before_filter :load_workflow, :only => [:edit, :update, :destroy]

  def index
    respond_to do |format|
      format.js
      format.json do
        self.load_workflows
        render :json => {:collection => self.assemble_records(@workflows), :total => @workflows_count}.to_json
      end
    end
  end
  
  def create
    @workflow = current_account.workflows.build(params[:workflow])
    @workflow.creator = @workflow.updator = current_user
    @created = @workflow.save
    respond_to do |format|
      format.js do
        self.render_json_response
      end
    end
  end
  
  def edit
    
  end
  
  def update
    @workflow.attributes = params[:workflow]
    @workflow.updator = current_user
    @updated = @workflow.save
    respond_to do |format|
      format.js do
        self.render_json_response
      end
    end
  end
  
  def destroy
    @destroyed = @workflow.destroy
    respond_to do |format|
      format.js do
        self.render_json_response
      end
    end
  end
  
  def destroy_collection
    @destroyed_items_size = 0
    @undestroyed_items_size = 0
    current_account.workflows.find(params[:ids].split(",").map(&:strip).reject(&:blank?)).to_a.each do |workflow|
      if workflow.destroy
        @destroyed_items_size += 1
      else
        @undestroyed_items_size += 1
      end
    end

    error_message = []
    error_message << "#{@destroyed_items_size} workflow(s) successfully deleted" if @destroyed_items_size > 0
    error_message << "#{@undestroyed_items_size} workflow(s) failed to be destroyed" if @undestroyed_items_size > 0

    flash_success :now, error_message.join(", ")
    respond_to do |format|
      format.js do
        render :json => {:flash => flash[:notice].to_s, :success => (@destroyed_items_size > 0)}.to_json  
      end
    end
  end
  
  protected
  
  def load_workflow
    @workflow = current_account.workflows.find(params[:id])
  end
  
  def load_workflows
    @workflows = current_account.workflows
    @workflows_count = current_account.workflows.size
  end
  
  def render_json_response
    errors = (@workflow.errors.full_messages.blank? ? ($! ? $!.message : "")  : render_to_string(:partial => "/shared/error_messages_for", :locals => {:symbol => :workflow})).to_s
    render :json => {:flash => flash[:notice].to_s, :close => @updated && @close, :errors => errors, 
                     :id => @workflow.id, :success => @updated || @created || false}.to_json
  end
  
  def assemble_records(records)
    out = []
    records.each do |record|
      out << self.assemble_record(record)
    end
    out
  end
  
  def assemble_record(record)
    {
      :id => record.id,
      :title => record.title,
      :description => record.description,
      :updated_by_name => record.updator ? record.updator.full_name : "",
      :created_by_name => record.creator ? record.creator.full_name : ""
    }
  end 
end
