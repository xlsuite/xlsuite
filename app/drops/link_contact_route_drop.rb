#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class LinkContactRouteDrop < Liquid::Drop
  attr_reader :link_contact_route
  delegate :name, :url, :formatted_url, :to => :link_contact_route

  def initialize(link_contact_route)
    @link_contact_route = link_contact_route
  end
end
