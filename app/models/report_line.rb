#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ReportLine
  attr_accessor :field, :operator, :value, :value2, :order, :excluded, :display

  def initialize(args={})
    args.each_pair do |key, value|
      raise ArgumentError, "Unknown attribute #{key.inspect}" unless self.respond_to?("#{key}=")
      self.send("#{key}=", value)
    end
  end
  
  def operator
    raise SubclassResponsibilityError
  end
  
  def value
    raise SubclassResponsibilityError
  end
  
  def value2
    raise SubclassResponsibilityError
  end

  def raw_value
    @value
  end

  def excluded?
    !self.excluded.blank?
  end
  
  def display?
    !self.display.blank?
  end
  
  def display_only?
    false
  end
  
  def time_field?
    self.field.match(/_(at|on)$/i)
  end
  
  def parsed_value
    self.time_field? ? Chronic.parse(self.value) : self.value
  end

  def add_conditions!(sql, sql_name, alias_name, conditions=[])
    sql[:conditions][0] << "#{sql_name} #{self.operator} :#{alias_name}"
    sql[:conditions][1] << {alias_name => self.parsed_value}
    sql[:order] << "#{alias_name} #{self.order}" if self.order =~ /asc|desc/i
  end
  
  def add_having!(sql, alias_name)
    sql[:having][0] << "#{alias_name} #{self.operator} :#{alias_name}"
    sql[:having][1] << {alias_name.to_sym => self.parsed_value}
  end

  def ==(other)
    self.class == other.class && self.field == other.field && self.value == other.value && self.excluded == other.excluded
  end

  def hash
    [self.class, self.field, self.value, self.excluded].map(&:hash).inject {|memo, value| memo ^ value}
  end

  class << self
    def using(operator)
      exists = Dir[File.join(RAILS_ROOT, "app", "models", "report_*_line.rb")].any? do |filename|
        File.basename(filename, ".rb").classify == operator
      end
      raise ArgumentError, "Unknown subtype of ReportLine: #{operator}" unless exists
      operator.constantize
    end
  end
end
