class SharedEmailAccount < ActiveRecord::Base
  belongs_to :target, :polymorphic => true
  belongs_to :email_account
  
  validates_presence_of :email_account_id, :target_type, :target_id

  validates_uniqueness_of :email_account_id, :scope => [:target_type, :target_id]
end
