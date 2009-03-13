#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class GroupItem < ActiveRecord::Base
  belongs_to :group
  belongs_to :target, :polymorphic => true
  
  validates_uniqueness_of :group_id, :scope => [:target_type, :target_id]
  validates_presence_of :group_id, :target_id, :target_type
  acts_as_list :scope => 'target_type = \"#{target_type}\" AND target_id = #{target_id}'
end
