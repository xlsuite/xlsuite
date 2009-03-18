class AddPointToParties < ActiveRecord::Migration
  def self.up
    add_column :parties, :point, :integer, :default => 0
  end

  def self.down
    remove_column :parties, :point
  end
end
