#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Assignee < ActiveRecord::Base
  belongs_to :account
  validates_presence_of :account_id
  before_validation {|a| a.account = a.task.account if a.task}

  belongs_to :task
  belongs_to :party

  acts_as_list :scope => :task
  
  validates_presence_of :task_id, :party_id
end
