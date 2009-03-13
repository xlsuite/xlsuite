#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

require "redcloth"

module Textilize
  def textilize(input)
    RedCloth.new(input, [:filter_html, :filter_styles]).to_html
  end
end
