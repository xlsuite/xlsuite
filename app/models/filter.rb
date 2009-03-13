#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Filter < ActiveRecord::Base
  belongs_to :account
  belongs_to :party
  belongs_to :email_label
  has_many :filter_lines, :dependent => :destroy
  has_and_belongs_to_many :emails, :order => "CONCAT_WS('', 'sent_at', 'received_at') DESC"
  validates_presence_of :account_id, :party_id, :name
end
