class ActionHandlerSequence < ActiveRecord::Base
  belongs_to :action_handler
  validates_presence_of :action_type, :action_handler_id, :time_reference
  
  TIME_REFERENCE_VALUES = ["start", "last_sequence"]
  validates_inclusion_of :time_reference, :in => TIME_REFERENCE_VALUES
end
