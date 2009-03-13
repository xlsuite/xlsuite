#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Polygon < ActiveRecord::Base
  belongs_to :account
  belongs_to :owner, :polymorphic => true

  validates_presence_of :account_id

  serialize :points, Array

  # I run a semi-infinite ray horizontally (increasing x, fixed y) out from the test point, and
  # count how many edges it crosses. At each crossing, the ray switches between inside and outside.
  # This is called the Jordan curve theorem.
  #
  # Reference:  http://www.ecse.rpi.edu/Homepages/wrf/Research/Short_Notes/pnpoly.html
  #             PNPOLY - Point Inclusion in Polygon Test, by W. Randolph Franklin (WRF)
  # Google Search: http://www.google.com/search?q=how+to+determine+if+a+point+is+within+a+polygon&ie=UTF-8&oe=UTF-8
  def include?(x, y)
    polySides = points.size
    j = polySides - 1
    inside = false

    transpose = self.points.transpose
    polyX, polyY = transpose.first, transpose.last

    # Convert points to float
    polyX.map!(&:to_f)
    polyY.map!(&:to_f)
    x = x.to_f
    y = y.to_f

    for i in (0..polySides-1) do
      if ((polyY[i] < y && polyY[j] >= y) || (polyY[j] < y && polyY[i] >= y)) then
        if ((polyX[i] + (y - polyY[i]) / (polyY[j] - polyY[i]) * (polyX[j] - polyX[i])) < x) then
          inside = !inside
        end
      end
      j = i
    end

    inside
  end

  def points=(object)
    object = self.class.str_to_array(object) if object.kind_of?(String)
    write_attribute(:points, object)
  end

  def to_liquid
    PolygonDrop.new(self)
  end

  def to_geocodes
    min_latitude, max_latitude   = points.map(&:first).min, points.map(&:first).max
    min_longitude, max_longitude = points.map(&:last).min, points.map(&:last).max
    geocodes = Geocode.find_all_by_latitude_and_longitude((min_latitude .. max_latitude), (min_longitude .. max_longitude))
    geocodes.select do |geocode|
      self.include?(geocode.latitude, geocode.longitude)
    end
  end

  # Class methods
  class << self
    # Converts a string of points such as "[[1,2],[3,4],[5.6,7.8]]" to an array of array of floats
    def str_to_array(string)
      return nil if string.blank?

      points = string.scan(/\[\s*([-+]?(?:(?:\d+(?:\.\d+)?)|(?:\.\d+)))\s*,\s*([-+]?(?:(?:\d+(?:\.\d+)?)|(?:\.\d+)))\s*\]/)
      points.map {|coords| coords.map(&:to_f)}
    end
  end
end
