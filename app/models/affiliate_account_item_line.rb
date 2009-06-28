class AffiliateAccountItemLine < ActiveRecord::Base
  belongs_to :affiliate_account_item
  belongs_to :target, :polymorphic => true
  
  acts_as_money :price
  acts_as_money :commission_amount
  
  acts_as_period :subscription_period, :allow_nil => true
  
  validates_presence_of :affiliate_account_item_id, :target_type, :target_id
  validates_uniqueness_of :target_id, :scope => [:affiliate_account_item_id, :target_type]
  
  def main_identifier
    case self.target
    when Account
      "XLsuite account signup for " + self.target.domains.map(&:name).join(", ")
    when Product
      self.target.name
    else
      raise "Affiliate account line item not yet supported"
    end
  end
  
  def subscription?
    !(self.subscription_period_unit.blank? or self.subscription_period_length.blank?)
  end
end
