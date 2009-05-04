#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class StepsController < ApplicationController
  required_permissions %w(index copy_step_index new create async_edit edit copy_from update destroy destroy_collection lines create_line update_line destroy_line reposition) => "current_user?"

  before_filter :load_workflow, :only => %w(index async_edit edit copy_from update destroy lines create_line update_line destroy_line reposition)
  before_filter :load_step, :only => %w(async_edit edit update destroy lines create_line update_line destroy_line)
  

  def index
    respond_to do |format|
      format.js
      format.json do
        self.load_steps
        render :json => {:collection => self.assemble_records(@steps), :total => @steps_count}.to_json
      end
    end
  end
  
  def copy_step_index
    respond_to do |format|
      format.js
      format.json do
        @steps = Account.find(params[:account_id]).steps
        @steps_count = current_account.steps.size
        render :json => {:collection => self.assemble_records(@steps), :total => @steps_count}.to_json
      end
    end
  end
  
  def new
    
  end
  
  def create
    @step = current_account.steps.build(params[:step])
    @created = @step.save
    respond_to do |format|
      format.js do
        self.render_json_response
      end
    end
  end
  
  def async_edit
    
  end
  
  def edit
    
  end
  
  def copy_from
    @step = @workflow.steps.build()
    copy_from_step = Step.find(params[:step_id])
    copy_from_step.copy_to_target_in_account(@step, @workflow.account, {:create_dependencies => true})
    @step.title = params[:title]
    @step.save
    respond_to do |format|
      format.js do
        return render(:template => "steps/async_edit.rjs")
      end
    end
  end
  
  def update
    if params[:step][:interval]
      params[:step][:interval] = params[:step][:interval].to_i * 60
    end
    activated = params[:step].delete(:activated)
    if activated =~ /true/i
      @step.activated_at = Time.now
    elsif activated =~ /false/i
      @step.activated_at = nil
    end
    @step.attributes = params[:step]
    @updated = @step.save
    respond_to do |format|
      format.js do
        self.render_json_response
      end
    end
  end
  
  def destroy
    step_id = @step.id
    @destroyed = @step.destroy
    if @destroyed
      flash_success :now, "Step successfully destroyed"
    else
      flash_failure :now, "Step '#{@step.title}' could not be destroyed"
    end
    respond_to do |format|
      format.js do
        errors = (@step.errors.full_messages.blank? ? ($! ? $!.message : "")  : render_to_string(:partial => "/shared/error_messages_for", :locals => {:symbol => :step})).to_s
        render :json => {:id => step_id, :flash => flash[:notice].to_s, :errors => errors, :no_steps_left => @workflow.steps.blank?}.to_json
      end
    end
  end
  
  def destroy_collection
    @destroyed_items_size = 0
    @undestroyed_items_size = 0
    current_account.steps.find(params[:ids].split(",").map(&:strip).reject(&:blank?)).to_a.each do |step|
      if step.destroy
        @destroyed_items_size += 1
      else
        @undestroyed_items_size += 1
      end
    end

    error_message = []
    error_message << "#{@destroyed_items_size} step(s) successfully deleted" if @destroyed_items_size > 0
    error_message << "#{@undestroyed_items_size} step(s) failed to be destroyed" if @undestroyed_items_size > 0

    flash_success :now, error_message.join(", ")
    respond_to do |format|
      format.js
    end
  end
  
  def lines
    results = []
    @step.lines.each do |line|
      results << truncate_line(line)
    end
    render :json => {:collection => results, :total => results.size}.to_json
  end
  
  def create_line
    @step.add_line(params[:line])
    @created = @step.save
    if @created
      flash_success :now, "Trigger line successfully added to step #{@step.title}"
    end
    self.render_json_response
  end
  
  def update_line
    params[:excluded] = params[:excluded] =~ /^(true|on)$/i ? true : false
    @step.update_line(params[:position], {:operator => params[:operator], :field => params[:field], :value => params[:value], :excluded => params[:excluded]})
    @updated = @step.save    
    if @updated
      flash_success :now, "Trigger line successfully updated for step #{@step.title}"
    end
    self.render_json_response
  end
  
  def destroy_line
    @step.destroy_line(params[:position]) 
    @updated = @step.save    
    if @updated
      flash_success :now, "Trigger line successfully destroyed"
    end
    respond_to do |format|
      format.js do
        render :json => {:success => true, :flash => flash[:notice].to_s}.to_json
      end
    end
  end
  
  def reposition
    ids = params[:ids].split(",").map(&:strip).to_a
    positions = params[:positions].split(",").map(&:strip).map(&:to_i).to_a
    Step.transaction do
      (0..ids.length-1).each do |i|
        @workflow.steps.find(ids[i]).update_attribute(:position, positions[i]+1)
      end
    end
    render :nothing => true
  end
  
  protected
  def truncate_line(record)
    {
      :id => @step.id*1000+record.object_id,
      :field => record.field || "",
      :operator => record.class.to_s || "",
      :value => record.raw_value || "",
      :excluded => record.excluded || false, 
      :order => record.order || false
    }
  end
  
  def load_workflow
    @workflow = current_account.workflows.find(params[:workflow_id])
  end
  
  def load_step
    @step = @workflow.steps.find(params[:id])
  end
  
  def load_steps
    @steps = @workflow.steps
    @steps_count = @workflow.steps.size
  end
  
  def render_json_response
    errors = (@step.errors.full_messages.blank? ? ($! ? $!.message : "")  : render_to_string(:partial => "/shared/error_messages_for", :locals => {:symbol => :step})).to_s
    render :json => {:flash => flash[:notice].to_s, :errors => errors, :interval => @step.interval/60,
                     :id => @step.id, :success => @updated || @created || false}.to_json
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
      :model_class_name => record.model_class_name, 
      :workflow => record.workflow.title,
      :workflow_id => record.workflow.id,
      :action_descriptions => record.tasks.map{|t|t.action.description}.join("<br />")
    }
  end 
end
