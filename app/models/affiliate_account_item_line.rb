class AffiliateAccountItemLine < ActiveRecord::Base
  belongs_to :affiliate_account_item
  belongs_to :target, :polymorphic => true
  
  acts_as_money :price
  acts_as_money :commission_amount
  
  acts_as_period :subscription_period, :allow_nil => true
  
  validates_presence_of :affiliate_account_item_id, :target_type, :target_id
  validates_uniqueness_of :target_id, :scope => [:affiliate_account_item_id, :target_type]
end
