#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Authorization < ActiveRecord::Base
  belongs_to :object, :polymorphic => true
  belongs_to :group
end
