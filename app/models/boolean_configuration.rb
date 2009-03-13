#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class BooleanConfiguration < IntegerConfiguration
  def value
    self.int_value?
  end
  
  def set_value(val)
    if val.kind_of?(Numeric) then
      self.int_value = val != 0
    elsif val.kind_of?(String) then
      self.int_value = val.to_i != 0
    else
      self.int_value = val ? 1 : 0
    end
  end
end
