#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class SharedEmailAccount < ActiveRecord::Base
  belongs_to :target, :polymorphic => true
  belongs_to :email_account
  
  validates_presence_of :email_account_id, :target_type, :target_id

  validates_uniqueness_of :email_account_id, :scope => [:target_type, :target_id]
end
