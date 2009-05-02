class CombineStepIntervalColumns < ActiveRecord::Migration
  def self.up
    add_column :steps, :interval, :integer, :default => 15.minutes.to_i
    remove_column :steps, :interval_length
    remove_column :steps, :interval_unit
  end

  def self.down
    add_column :steps, :interval_length, :integer, :default => 15
    add_column :steps, :interval_unit, :string, :default => "minutes"
    remove_column :steps, :interval
  end
end
