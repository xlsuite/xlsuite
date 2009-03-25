class RenamePointToOwnPointInParties < ActiveRecord::Migration
  def self.up
    rename_column :parties, :point, :own_point
  end

  def self.down
    rename_column :parties, :own_point, :point
  end
end
