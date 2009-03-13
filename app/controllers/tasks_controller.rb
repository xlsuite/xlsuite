#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class TasksController < ApplicationController
  required_permissions %w(index new create edit update destroy destroy_collection add_assignee reposition update_action) => "current_user?"
  before_filter :load_workflow
  before_filter :load_step
  before_filter :load_task, :only => %w(edit update update_action destroy add_assignee)

  def index
    self.load_tasks
    return render(:json => {:collection => self.assemble_records(@tasks), :total => @tasks_count}.to_json)
  end
  
  def new
    
  end
  
  def create
    @task = @step.tasks.build(params[:task])
    if params[:action_type]
      @task.action = params[:action_type].constantize.new()
    end
    @created = @task.save
    respond_to do |format|
      format.js do
        self.render_json_response
      end
    end
  end
  
  def edit
    @action = @task.action
    respond_to do |format|
      format.js
    end
  end
  
  def update
    @task.attributes = params[:task]
    @updated = @task.save
    if @updated
      flash_success :now, "Task successfully updated"
    else
      flash_failure :now, "Updating of task failed"
    end
    respond_to do |format|
      format.js do
        self.render_json_response
      end
    end
  end
  
  def update_action
    params["_action"].each_pair do |key, value|
      @task.action.send("#{key}=", value)
    end
    @updated = @task.save
    respond_to do |format|
      format.js do
        self.render_json_response
      end
    end
  end
  
  def destroy
    @destroyed = @task.destroy
    if @destroyed
      flash_success :now, "Task successfully destroyed"
    else
      flash_failure :now, "Task could not be destroyed"
    end
    respond_to do |format|
      format.js do
        self.render_json_response
      end
    end
  end
  
  def destroy_collection
    @destroyed_items_size = 0
    @undestroyed_items_size = 0
    current_account.tasks.find(params[:ids].split(",").map(&:strip).reject(&:blank?)).to_a.each do |task|
      if task.destroy
        @destroyed_items_size += 1
      else
        @undestroyed_items_size += 1
      end
    end

    error_message = []
    error_message << "#{@destroyed_items_size} task(s) successfully deleted" if @destroyed_items_size > 0
    error_message << "#{@undestroyed_items_size} task(s) failed to be destroyed" if @undestroyed_items_size > 0

    flash_success :now, error_message.join(", ")
    respond_to do |format|
      format.js
    end
  end
  
  def reposition
    ids = params[:ids].split(",").map(&:strip).to_a
    positions = params[:positions].split(",").map(&:strip).map(&:to_i).to_a
    OrderLine.transaction do
      (0..ids.length-1).each do |i|
        @step.tasks.find(ids[i]).update_attribute(:position, positions[i]+1)
      end
    end
    render :nothing => true
  end
  
  protected
  def load_workflow
    @workflow = current_account.workflows.find(params[:workflow_id])
  end
  
  def load_step
    @step = @workflow.steps.find(params[:step_id])
  end
  
  def load_task
    @task = @step.tasks.find(params[:id])
  end
  
  def load_tasks
    @tasks = @step.tasks
    @tasks_count = @tasks.size
  end
  
  def render_json_response
    errors = (@task.errors.full_messages.blank? ? ($! ? $!.message : "")  : render_to_string(:partial => "/shared/error_messages_for", :locals => {:symbol => :task})).to_s
    render :json => {:flash => flash[:notice].to_s, :close => @updated && @close, :errors => errors, 
                     :id => @task.id, :success => @updated || @created || false}.to_json
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
      :assignees => record.assignees_as_text,
      :description => record.action.description || ""
    }
  end 
end
