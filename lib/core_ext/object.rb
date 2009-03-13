#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Object
  def instance_variable_exists?(name)
    self.instance_variables.include?("@"+name.to_s)
  end
end
