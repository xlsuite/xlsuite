#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class MeasurementUnit
  ShortMetricUnits    = {:maxi => 'm', :mini => 'cm'}.freeze
  LongMetricUnits     = {:maxi => 'meters', :mini => 'centimeters'}.freeze
  ShortImperialUnits  = {:maxi => 'ft', :mini => 'in'}.freeze
  LongImperialUnits   = {:maxi => 'feet', :mini => 'inches'}.freeze

  MetricUnits         = {:short_name => ShortMetricUnits, :long_name => LongMetricUnits}.freeze
  ImperialUnits       = {:short_name => ShortImperialUnits, :long_name => LongImperialUnits}.freeze
  MeasurementUnits    = {:imperial => ImperialUnits, :metric => MetricUnits}.freeze

  def self.to_name(unit, style, length)
    units = MeasurementUnits[unit]
    raise "Unknown measurement unit '#{unit}' (#{unit.class})" unless units
    styles = units[style]
    raise "Unknown measurement unit style '#{style}' (#{style.class})" unless styles
    name = styles[length]
    raise "Unknown measurement unit style length '#{length}' (#{length.class})" unless name
    name
  end
end
