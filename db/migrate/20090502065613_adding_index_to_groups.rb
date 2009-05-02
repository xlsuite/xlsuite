class AddingIndexToGroups < ActiveRecord::Migration
  def self.up
    add_index :groups, [:account_id, :label], :name => "by_account_label"
  end

  def self.down
    remove_index :groups, :name => "by_account_label"
  end
end
