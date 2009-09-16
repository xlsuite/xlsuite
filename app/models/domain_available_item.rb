class DomainAvailableItem < ActiveRecord::Base
  validates_presence_of :domain_id, :account_id, :item_type, :item_id
  validates_uniqueness_of :domain_id, :scope => [:item_id, :item_type]
  belongs_to :item, :polymorphic => true
  belongs_to :domain
end
