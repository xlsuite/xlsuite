#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module DestinationsHelper
  
  def destination_country_selections
    countries = AddressContactRoute::COUNTRIES.dup
    countries.unshift("All Others")
  end
end
