#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ReportStartsWithLine < ReportLine
  def operator
    self.excluded? ? "NOT LIKE" : "LIKE"
  end
  
  def value
    "#{@value}%"
  end
end
