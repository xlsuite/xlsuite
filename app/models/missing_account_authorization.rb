#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class MissingAccountAuthorization < RuntimeError
  def initialize(option_name)
    super "Authorization #{option_name} not granted on account"
  end
end
