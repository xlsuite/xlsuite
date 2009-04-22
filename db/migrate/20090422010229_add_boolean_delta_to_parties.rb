class AddBooleanDeltaToParties < ActiveRecord::Migration
  def self.up
    add_column :parties, :delta, :boolean, :default => false
  end

  def self.down
    remove_column :parties, :delta
  end
end
