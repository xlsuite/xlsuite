class ChangeDefaultValueOfPrivateInGroups < ActiveRecord::Migration
  def self.up
    change_column :groups, :private, :boolean, :default => true
  end

  def self.down
    change_column :groups, :private, :boolean, :default => false
  end
end
