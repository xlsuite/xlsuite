class AddingAccountIdUuidIndexToAssets < ActiveRecord::Migration
  def self.up
    add_index :assets, [:account_id, :uuid], :name => :by_account_id_uuid
  end

  def self.down
    remove_index :assets, :name => :by_account_id_uuid
  end
end
