class ActionHandlerMembership < ActiveRecord::Base
  belongs_to :action_handler
  belongs_to :party
  belongs_to :domain
  
  validates_presence_of :action_handler_id, :party_id, :domain_id
  validates_uniqueness_of :party_id, :scope => [:action_handler_id, :domain_id]
end
