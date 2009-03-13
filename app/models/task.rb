#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Task < ActiveRecord::Base
  belongs_to :account
  validates_presence_of :account_id
  before_validation {|t| t.account = t.step.account if t.step}

  belongs_to :step
  acts_as_list :scope => :step

  has_many :assignees, :order => "position"

  validates_presence_of :step_id

  serialize :data, Hash
  
  before_create :generate_random_uuid

  def data
    read_attribute(:data) || write_attribute(:data, Hash.new)
  end

  def action
    data[:action] || self.action = Action.new
  end

  def action=(value)
    data[:action] = value
  end
  
  def description
    self.send(:read_attribute, :description).blank? ? self.action.description : self.send(:read_attribute, :description)
  end
  
  def assignees_as_text
    self.assignees.blank? ? "None" : self.assignees.reject(&:blank?).map{|p|p.party.full_name || p.party.display_name}.join(", ") 
  end

  def run(models)
    self.action.run_against(models, {:account => self.account, :task_id => self.id, :step_id => self.step_id}) if self.assignees.empty?
  end
  
  def attributes_for_copy_to(account)
    attributes = self.attributes.dup.symbolize_keys.merge(:account_id => account.id, :position => nil)
    attributes.delete(:step_id)
    attributes.delete(:data)
    attributes
  end
  
  def copy_to_target(target, account, options={})
    target.attributes = self.attributes_for_copy_to(account)
    target.action = self.action.duplicate(account, options)
    target.save!
  end
end
