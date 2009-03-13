#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Categorizable < ActiveRecord::Base
  belongs_to :category
  belongs_to :subject, :polymorphic => true
  
  validates_presence_of :category_id, :subject_type, :subject_id
end
