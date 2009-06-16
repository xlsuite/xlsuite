class AffiliateAccountItem < ActiveRecord::Base
  attr_protected :level

  belongs_to :affiliate_account
  belongs_to :target, :polymorphic => true
  
  validates_presence_of :affiliate_account_id, :level, :target_type, :target_id
  validates_uniqueness_of :affiliate_account_id, :scope => [:target_type, :target_id]
  validates_uniqueness_of :level, :scope => [:target_type, :target_id]
  
  before_create :set_level
  
  protected
  
  def set_level
    max_level = self.class.maximum(:level, :conditions => {:target_type => self.target_type, :target_id => self.target_id})
    if max_level
      self.level = max_level + 1
    else
      self.level = 1
    end
    true
  end
end
