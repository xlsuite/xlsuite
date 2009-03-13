#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class FloatConfiguration < Configuration
  def value
    self.float_value
  end

  def set_value(val)
    self.float_value = val.nil? ? nil : Float(val)
  end
end
