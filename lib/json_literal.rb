#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class JsonLiteral
  def initialize(value)
    @value = value
  end

  def to_json
    @value.to_s
  end

  alias_method :to_s, :to_json
end
