#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ContactRequestDrop < Liquid::Drop
  attr_reader :contact_request
  delegate :name, :email, :phone, :time_to_call, :subject, :body, :referrer_url, :tag_list, :created_at,
    :party, :completed_at, :approved_at, :recipients, :affiliate, :to => :contact_request
  
  def initialize(contact_request)
    @contact_request = contact_request
  end
end
