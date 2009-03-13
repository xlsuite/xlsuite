#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Geocode < ActiveRecord::Base
  validates_presence_of :zip, :latitude, :longitude
  validates_uniqueness_of :zip

  def self.find_by_zip(zip)
    raise ArgumentError, "ZIP required to find by zip: #{zip.inspect}" if zip.blank?
    geocode = find(:first, :conditions => ["zip = ?", zip])
    return geocode if geocode
    find(:first, :conditions => ["zip LIKE ?", zip.chop + "%"])
  end
end
