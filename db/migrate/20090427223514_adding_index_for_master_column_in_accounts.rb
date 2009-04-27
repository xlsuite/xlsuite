class AddingIndexForMasterColumnInAccounts < ActiveRecord::Migration
  def self.up
    add_index :accounts, :master, :name => "by_master"
  end

  def self.down
  end
end
