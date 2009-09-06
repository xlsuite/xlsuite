class ActionHandlerSequencesController < ApplicationController
  required_permissions :none
  
  before_filter :load_action_handler
  
  def index
    respond_to do |format|
      format.json do
        sequences = self.assemble_records(@action_handler.sequences)
        render(:json => {:total => sequences.size, :collection => sequences}.to_json)
      end
    end
  end
  
  def create
    sequence = ActionHandlerSequence.new(:action_handler => @action_handler)
    sequence.attributes = params[:sequence]
    created = sequence.save
    respond_to do |format|
      format.js do
        render(:json => {:success => created}.to_json)
      end
    end
  end
  
  def update
    sequence = @action_handler.sequences.find(params[:id])
    sequence.attributes = params[:sequence]
    updated = sequence.save
    respond_to do |format|
      format.js do
        render(:json => {:success => updated, :errors => sequence.errors.full_messages.join(",")}.to_json)
      end
    end
  end
  
  def update_ordering
  end
  
  def destroy_collection
    sequences = ActionHandlerSequence.all(:conditions => {:action_handler_id => @action_handler.id, :id => params[:ids].split(",").map(&:strip).map(&:to_i)})
    result = sequences.map(&:destroy).all?
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
    end
    out
  end

  def load_action_handler
    @action_handler = ActionHandler.find(:conditions => {:account_id => self.current_account.id, :id => params[:action_handler_id]})
  end
  
  def authorized?
    true
  end
end
