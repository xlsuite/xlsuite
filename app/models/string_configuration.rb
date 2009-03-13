#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class StringConfiguration < Configuration
  def value()
    self.str_value
  end

  def set_value(val)
    self.str_value = val.nil? ? nil : val.to_s.strip
  end
end
