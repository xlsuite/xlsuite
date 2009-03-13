#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ConfigurationNotFoundException < RuntimeError
  attr_reader :name

  def initialize(name)
    @name = name
    super "Could not find configuration named #{@name.inspect}"
  end
end
