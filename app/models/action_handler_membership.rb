class ActionHandlerMembership < ActiveRecord::Base
  belongs_to :action_handler
  belongs_to :party
  belongs_to :domain
  
  validates_presence_of :action_handler_id, :party_id, :domain_id
  validates_uniqueness_of :party_id, :scope => [:action_handler_id, :domain_id]
  
  after_destroy :delete_completed_sequences
  
  protected
  def delete_completed_sequences
    ActionHandlerPartyCompletedSequence.delete_all({:party_id => self.party.id, :domain_id => self.domain.id})
  end
end
