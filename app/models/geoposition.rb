#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Geoposition < ActiveRecord::Base
  def main_identifier
    "#{self.latitude} : #{self.longitude}"
  end
end
