#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class IntegerConfiguration < Configuration
  def value
    self.int_value
  end

  def set_value(val)
    self.int_value = val.nil? ? nil : Integer(val)
  end
end
