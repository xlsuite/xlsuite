#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module ReferralsHelper
  include ListingsHelper
  
  def referral_header(object)
    return "" unless object
    header = ""
    [:label, :name, :title].each do |method|
      header = object.send(method) if object.respond_to?(method)
    end
    case object
    when Listing
      header = render_listing_address_area_city_and_zip(object)
    end
    header
  end
end
