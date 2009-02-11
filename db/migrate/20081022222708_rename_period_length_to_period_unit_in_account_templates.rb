class RenamePeriodLengthToPeriodUnitInAccountTemplates < ActiveRecord::Migration
  def self.up
    rename_column :account_templates, :period_length, :period_unit
  end

  def self.down
    rename_column :account_templates, :period_unit, :period_length
  end
end
