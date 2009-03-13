#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Distance
  attr_reader :value, :unit

  def initialize(value, unit)
    @value, @unit = @value, @unit
  end

  def to_s
    "%.3f %s" % [@value || 0, @unit]
  end
end
