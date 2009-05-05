class AddingIndexesToGroups < ActiveRecord::Migration
  def self.up
    add_index :groups, [:account_id, :parent_id], :name => "by_account_parent"
  end

  def self.down
    remove_index :groups, :name => "by_account_parent"
  end
end
