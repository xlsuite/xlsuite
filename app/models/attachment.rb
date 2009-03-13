#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Attachment < ActiveRecord::Base
  belongs_to :email
  belongs_to :asset
  validates_presence_of :email_id, :asset_id

  delegate :content_type, :filename, :size, :current_data, :to => :asset
  before_save :generate_random_uuid

  class << self
    def find_by_uuid!(uuid)
      find_by_uuid(uuid).if_nil { raise ActiveRecord::RecordNotFound, "Could not find attachment with UUID #{uuid.inspect}" }
    end
  end
end
