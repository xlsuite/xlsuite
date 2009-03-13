#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class PolygonDrop < Liquid::Drop
  attr_reader :polygon
  delegate :points, :owner, :open, :open?, :to => :polygon

  def initialize(polygon)
    @polygon = polygon
  end
  
  def points_as_string
    self.points.inspect
  end
end
