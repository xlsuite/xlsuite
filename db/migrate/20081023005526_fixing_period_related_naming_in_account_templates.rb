class FixingPeriodRelatedNamingInAccountTemplates < ActiveRecord::Migration
  def self.up
    rename_column :account_templates, :period_unit, :period_length
    rename_column :account_templates, :period_duration, :period_unit
  end

  def self.down
    rename_column :account_templates, :period_unit, :period_duration
    rename_column :account_templates, :period_length, :period_unit
  end
end
