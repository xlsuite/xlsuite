#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module XlSuite
  module SlugHelper
    def to_slug
      self.strip.downcase.gsub(/[^-. \w]/, '_').gsub(' ', '-').gsub(/_+$/, '')
    end
  end
end
