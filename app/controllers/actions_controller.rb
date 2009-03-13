#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ActionsController < ApplicationController
  required_permissions %w(index new create edit update destroy destroy_collection) => "current_user?"
  before_filter :load_task
  before_filter :load_action, :only => [:edit, :update, :destroy]

  def index
    respond_to do |format|
      format.js
      format.json do
        self.load_actions
        render :json => {:collection => self.assemble_records(@actions), :total => @actions_count}.to_json
      end
    end
  end
  
  def new
    
  end
  
  def create
    @action = @task.actions << params[:action_type].constantize.new()
    @created = @task.save
    @position = @task.actions.size-1
    respond_to do |format|
      format.js do
        self.render_json_response
      end
    end
  end
  
  def edit
    respond_to do |format|
      format.js
    end
  end
  
  def update
    params["_action"].each_pair do |key, value|
      @action.send("#{key}=", value)
    end
    @updated = @task.save
    respond_to do |format|
      format.js do
        self.render_json_response
      end
    end
  end
  
  def destroy
    @task.actions.delete_at(params[:id].to_i)
    @destroyed = @task.save
    if @destroyed
      flash_success :now, "Action for Task #{@task.title} successfully destroyed"
    else
      flash_failure :now, "Action could not be destroyed"
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
    current_account.actions.find(params[:ids].split(",").map(&:strip).reject(&:blank?)).to_a.each do |action|
      if action.destroy
        @destroyed_items_size += 1
      else
        @undestroyed_items_size += 1
      end
    end

    error_message = []
    error_message << "#{@destroyed_items_size} action(s) successfully deleted" if @destroyed_items_size > 0
    error_message << "#{@undestroyed_items_size} action(s) failed to be destroyed" if @undestroyed_items_size > 0

    flash_success :now, error_message.join(", ")
    respond_to do |format|
      format.js
    end
  end
  
  protected
  def load_task
    @task = current_account.tasks.find(params[:task_id])
  end
  
  def load_action
    @action = @task.actions[params[:id].to_i]
    @position = params[:id].to_i
  end
  
  def load_actions
    @actions = @task.actions
    @actions_count = @actions.size
  end
  
  def render_json_response
    errors = (@task.errors.full_messages.blank? ? ($! ? $!.message : "")  : render_to_string(:partial => "/shared/error_messages_for", :locals => {:symbol => :task})).to_s
    render :json => {:flash => flash[:notice].to_s, :close => @updated && @close, :errors => errors, 
                       :id => @position, :success => @updated || @created }.to_json
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
      :description => record.description
    }
  end 
end
