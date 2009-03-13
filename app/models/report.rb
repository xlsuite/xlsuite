#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Report < ActiveRecord::Base
  belongs_to :owner, :class_name => "Party", :foreign_key => "owner_id"
  belongs_to :account
  
  serialize :lines, Array
  
  validates_presence_of :model
  
  def after_initialize
    self.lines ||= Array.new
  end
  
  def lines=(ls)
    ls = ls.to_a.sort_by {|e| e.first.to_i}.map(&:last) if ls.kind_of?(Hash)
    ls.collect! do |line|
      next line if line.kind_of?(ReportLine)
      ReportLine.using(line.delete("operator")).new(line)
    end

    write_attribute(:lines, ls)
  end

  def actual_model
    self.model.constantize
  end

  def column_named(name)
    self.actual_model.report_columns.detect {|col| col.name == name}
  end

  def columns
    columns = self.user_selected_columns
    column_names = columns.map{|e| e[:name]}
    self.real_columns_from_model.each do |real_column|
      next if column_names.index(real_column[:name])
      columns << real_column
    end
    columns
  end

  def user_selected_columns
    self.lines.map do |line|
      column = self.column_named(line.field)
      {:name => column.name, :human_name => column.human_name, :display => line.display?}
    end
  end

  def real_columns_from_model
    self.actual_model.real_columns.map do |column|
      {:name => column.name, :human_name => column.human_name, :display => true}
    end
  end

  def run(options={}, sort_field=nil, sort_mode=nil)
    return [] if self.lines.blank?
    ls = self.lines.dup
    ls << ReportDisplayOnlyLine.new(:field => sort_field, :order => sort_mode) unless sort_field.blank?
 
    self.execute(:run_report, ls, options)
  end
  
  def count_total_results(options={})
    self.execute(:count_report, self.lines, options)
  end

  protected
  def execute(method, lines, options)
    obj = self.model.downcase.pluralize
    self.account.send(obj).send(method, self.account, lines, options)
  end
end
