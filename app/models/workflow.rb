#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Workflow < ActiveRecord::Base
  belongs_to :account
  validates_presence_of :account_id

  belongs_to :creator, :class_name => "Party", :foreign_key => "creator_id"
  validates_presence_of :creator_id

  belongs_to :updator, :class_name => "Party", :foreign_key => "updator_id"
  validates_presence_of :updator_id

  has_many :steps, :order => "position", :dependent => :destroy

  validates_presence_of :title

  before_create :generate_random_uuid

  def run
    self.steps.each(&:run)
  end  
  
  def attributes_for_copy_to(account)
    account_owner_id = account.owner ? account.owner.id : nil
    self.attributes.dup.symbolize_keys.merge(:account_id => account.id, :creator_id => account_owner_id, 
          :updator_id => account_owner_id)
  end
  
  def copy_steps_from!(workflow, options={})
    Workflow.transaction do
      workflow.steps.each do |step|
        t_step = self.steps.find_by_uuid(step.uuid)
        if t_step
          t_step.attributes = step.attributes_for_copy_to(self.account) if options[:overwrite]
          t_step.save
        else
          t_step = self.steps.build()
          step.copy_to_target_in_account(t_step, self.account, options)
        end
      end
    end
  end
end
