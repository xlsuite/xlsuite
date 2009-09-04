class ActionHandlersController < ApplicationController
  required_permissions :none
  before_filter :load_action_handler, :only => %w(edit update)
  
  def index
    respond_to do |format|
      format.js
      format.json do
        action_handlers = ActionHandler.all(:conditions => {:account_id => self.current_account.id}, :order => "name")
        render(:json => {:collection => self.assemble_records(action_handlers), :total => action_handlers.size}.to_json)
      end
    end
  end
  
  def create
    action_handler = ActionHandler.new(:account => self.current_account)
    if params[:action_handler].delete(:activate_now)
      params[:action_handler][:activated_at] = Time.now.utc
    end
    action_handler.attributes = params[:action_handler]
    created = action_handler.save
    respond_to do |format|
      format.js do
        render(:json => {:success => created, :errors => action_handler.errors.full_messages.join(", ")}.to_json)
      end
    end
  end
  
  def edit
    respond_to do |format|
      format.js
    end
  end
  
  def update
    @action_handler.attributes = params[:action_handler]
    updated = @action_handler.save
    respond_to do |format|
      format.js do
        render(:json => {:success => updated, :errors => @action_handler.errors.full_messages.join(",")}.to_json)
      end
    end
  end
  
  def destroy_collection
    action_handlers = ActionHandler.find(params[:ids].split(",").map(&:strip).map(&:to_i))
    result = action_handlers.map(&:destroy).all?
    respond_to do |format|
      format.js do
        render(:json => {:success => result}.to_json)
      end
    end
  end
  
protected
  def assemble_records(records)
    out = []
    records.each do |record|
      out << {
        :id => record.id,
        :name => record.name,
        :label => record.label,
        :description => record.description,
        :activated_on => (record.activated_at ? record.activated_at.strftime(DATE_STRFTIME_FORMAT) : ""),
        :deactivated_on => (record.deactivated_at ? record.deactivated_at.strftime(DATE_STRFTIME_FORMAT) : "")
      }
    end
    out
  end
  
  def load_action_handler
    @action_handler = ActionHandler.find(params[:id])
  end
  
  def authorized?
    true
  end
end
