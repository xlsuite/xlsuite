#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

require "white_list_helper"

module Whitelist
  include WhiteListHelper

  def whitelist(input)
    white_list(input)
  end
end
