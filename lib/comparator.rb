#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module Comparator
  def nil_safe_case_insensitive_compare(a, b)
    if a.blank? and b.blank? then          0
    elsif a.blank? and not b.blank? then  -1
    elsif not a.blank? and b.blank? then   1
    else                                  a.downcase <=> b.downcase
    end
  end
end
