#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ReportGreaterThanLine < ReportLine
  def operator
    self.excluded? ? "<=" : ">"
  end
  
  def value
    "#{@value}"
  end
end
