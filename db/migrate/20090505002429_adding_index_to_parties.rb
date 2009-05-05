class AddingIndexToParties < ActiveRecord::Migration
  def self.up
    add_index :parties, [:account_id, :profile_id], :name => "by_account_profile"
  end

  def self.down
    remove_index :parties, :name => "by_account_profile"
  end
end
