#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class BadFieldException < RuntimeError
  def initialize(field, model)
    @field, @model = field, model
  end

  def message
    "The #{@field.inspect} field is unknown in models of type #{@model}"
  end
end
