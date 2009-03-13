#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Rent < Listing
  
  def gmap_query
    self.raw_property_data["Address"] || ""
  end
  
  def to_liquid
    ListingDrop.new(self)
  end
end
