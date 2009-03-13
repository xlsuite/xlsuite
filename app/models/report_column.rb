#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ReportColumn
  attr_accessor :human_name, :name, :virtual, :model, :relationship, :table_name
  
  def initialize(args={})
    args.each_pair do |key, value|
      raise ArgumentError, "Unknown attribute #{key.inspect}" unless self.respond_to?("#{key}=")
      self.send("#{key}=", value)
    end
  end
  
  def model=(name)
    raise ArgumentError, "Must be a string" unless name.kind_of?(String)
    @model = name
  end

  def actual_model
    @model.constantize
  end

  def to_report_sql(line, sql, origin)
    attr_name = if self.relationship then
                  attr_name = self.name.gsub(self.relationship.singularize + "_", "")
                  sql_name = "#{self.table_name}.#{attr_name}"
                else
                  attr_name = self.name
                  sql_name = "#{self.actual_model.table_name}.#{attr_name}"
                end
    sql[:select] << "#{sql_name} AS #{self.name}"

    if self.relationship then
      join_method = "join_on_#{self.relationship}"
      join_method << "_as_#{self.table_name}" if self.relationship != self.table_name
      sql[:joins] << origin.send(join_method)
    end

    line.add_conditions!(sql, sql_name, self.name)
  end

  def virtual?
    !self.virtual.blank?
  end
  
  def real?
    self.virtual.blank?
  end

  def to_s
    self.human_name
  end
end
