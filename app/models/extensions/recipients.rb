#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module Extensions
  module Recipients
    def to_formatted_s
      self.find(:all).map(&:to_formatted_s).join(", ")
    end
  end
end
