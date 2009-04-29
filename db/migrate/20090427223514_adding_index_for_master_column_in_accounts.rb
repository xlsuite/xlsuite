class AddingIndexForMasterColumnInAccounts < ActiveRecord::Migration
  def self.up
    add_index :accounts, :master, :name => "by_master"
  end

  def self.down
    remove_index :accounts, :name => "by_master"
  end
end
