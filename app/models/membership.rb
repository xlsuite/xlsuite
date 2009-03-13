#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Membership < ActiveRecord::Base
  acts_as_taggable
  acts_as_reportable :columns => %w(created_at)
  
  belongs_to :party
  belongs_to :group

  class << self
    def join_on_groups
      ["INNER JOIN groups ON groups.id = memberships.group_id"]
    end
    
    def join_on_parties
      ["INNER JOIN parties ON parties.id = memberships.party_id"]
    end
  end
end
