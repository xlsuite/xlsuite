#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ExpiringPartyItem < ActiveRecord::Base
  belongs_to :party
  validates_presence_of :party_id
  
  belongs_to :item, :polymorphic => true
  validates_presence_of :item_type, :item_id
  
  validates_uniqueness_of :party_id, :scope => [:item_type, :item_id]
  
  validates_presence_of :started_at
  
  belongs_to :created_by, :polymorphic => true
  belongs_to :updated_by, :polymorphic => true
  
  after_create :join_group
  after_destroy :leave_group
  
  protected
  
  def join_group
    if self.item.kind_of?(Group)
      self.party.memberships.create(:group => self.item) unless self.party.memberships.find_by_group_id(self.item.id)
    end
  end
  
  def leave_group
    if self.item.kind_of?(Group)
      self.party.memberships.find(:first, :conditions => {:group_id => self.item.id}).destroy
    end
  end
end
