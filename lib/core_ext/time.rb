#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Time
  def to_http_header_format
    strftime("%a, %d %b %Y %H:%M:%S GMT")
  end
end
