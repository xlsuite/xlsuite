class ActionHandlerPartyCompletedSequence < ActiveRecord::Base
  belongs_to :account
  belongs_to :domain
  belongs_to :party
  belongs_to :action_handler_sequence
  
  validates_presence_of :domain_id, :account_id, :party_id, :action_handler_sequence_id
  validates_uniqueness_of :party_id, :scope => [:domain_id, :action_handler_sequence_id]
end
