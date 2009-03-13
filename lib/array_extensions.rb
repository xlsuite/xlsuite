#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Array
  def to_selection_list
    self.map {|s| [s, s.downcase.gsub(' ', '-')]}
  end
end
