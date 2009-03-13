#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class AssigneesController < ApplicationController
  required_permissions %w(index new create create_collection edit update destroy destroy_collection mark_completed unmark_completed reposition) => "current_user?"
  before_filter :load_task, :only => %w(index create_collection update destroy destroy_collection mark_completed unmark_completed reposition)
  before_filter :load_assignee, :only => [:update, :destroy, :mark_completed, :unmark_completed]

  def index
    respond_to do |format|
      format.js
      format.json do
        self.load_assignees
        render :json => {:collection => self.assemble_records(@assignees), :total => @assignees_count}.to_json
      end
    end
  end
  
  def new
    
  end
  
  def create
    
  end
  
  def create_collection
    @assignees_created = 0
    params[:party_ids].split(",").map(&:strip).reject(&:blank?).to_a.each do |party_id|  
      @task.assignees.create!(:party_id => party_id)
      @assignees_created += 1
    end
    flash_success "#{@assignees_created} assignees successfully created for task"
    respond_to do |format|
      format.js do
        render :json => {:flash => flash[:notice].to_s, :success => true }.to_json
      end
    end
  rescue
    respond_to do |format|
      format.js do
        render :json => {:success => false, :errors => $!.message}
      end
    end
  end
  
  def edit
    
  end
  
  def update
    case params[:assignee].delete(:completed)
    when /^true$/i  
      @assignee.completed_at = Time.now()
      flash_success :now, "Assignee #{@assignee.party.display_name} for task successfully marked as completed"
    when /^false$/i
      @assignee.completed_at = nil
      flash_success :now, "Assignee #{@assignee.party.display_name} for task successfully marked as incomplete"
    end
    @updated = @assignee.save
    respond_to do |format|
      format.js do
        render :json => self.assemble_record(@assignee).merge!(:flash => flash[:notice].to_s).to_json
      end
    end
  end
  
  def destroy
    @destroyed = @assignee.destroy
    if @destroyed
      flash_success :now, "Assignee successfully removed from task"
    else
      flash_failure :now, "Assignee could not be destroyed"
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
    current_account.assignees.find(params[:ids].split(",").map(&:strip).reject(&:blank?)).to_a.each do |assignee|
      if assignee.destroy
        @destroyed_items_size += 1
      else
        @undestroyed_items_size += 1
      end
    end

    error_message = []
    error_message << "#{@destroyed_items_size} assignee(s) successfully deleted" if @destroyed_items_size > 0
    error_message << "#{@undestroyed_items_size} assignee(s) failed to be destroyed" if @undestroyed_items_size > 0

    flash_success :now, error_message.join(", ")
    respond_to do |format|
      format.js
    end
  end
  
  def reposition
    ids = params[:ids].split(",").map(&:strip).to_a
    positions = params[:positions].split(",").map(&:strip).map(&:to_i).to_a
    Assignee.transaction do
      (0..ids.length-1).each do |i|
        @task.assignees.find(ids[i]).update_attribute(:position, positions[i]+1)
      end
    end
    render :nothing => true
  end
  
  def mark_completed
    @assignee.completed_at = Time.now
    @assignee.save!
    flash_success :now, "Assignee marked as completed"
    respond_to do |format|
      format.js
    end
  end
  
  def unmark_completed
    @assignee.completed_at = nil
    @assignee.save!
    flash_success :now, "Assignee unmarked as completed"
    respond_to do |format|
      format.js
    end
  end
  
  protected
  def load_task
    @task = current_account.tasks.find(params[:task_id])
  end
  
  def load_assignee
    @assignee = current_account.assignees.find(params[:id])
  end
  
  def load_assignees
    @assignees = @task.assignees
    @assignees_count = @assignees.size
  end
  
  def render_json_response
    errors = (@assignee.errors.full_messages.blank? ? ($! ? $!.message : "")  : render_to_string(:partial => "/shared/error_messages_for", :locals => {:symbol => :assignee})).to_s
    render :json => {:flash => flash[:notice].to_s, :close => @updated && @close, :errors => errors, 
                     :id => @assignee.id, :success => @updated || @created }.to_json
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
      :display_name => record.party.display_name,
      :email => record.party.main_email.email_address ? record.party.main_email.email_address : "",
      :completed_at => record.completed_at,
      :completed => record.completed_at ? true: false
    }
  end
end
