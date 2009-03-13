#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ReportDisplayOnlyLine < ReportLine
  def add_conditions!(sql, sql_name, alias_name, conditions=[])
    sql[:conditions][0] += conditions unless conditions.blank?
    sql[:order] << "#{alias_name} #{self.order}" if self.order =~ /asc|desc/i
  end
  
  def value
    nil
  end
  
  def value2
    nil
  end
  
  def operator
    nil
  end

  def display_only?
    true
  end
end
