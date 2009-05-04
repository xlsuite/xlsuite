class AddingIndexesToRecipients < ActiveRecord::Migration
  def self.up
    add_index :recipients, [:account_id, :type], :name => "by_account_type"
    add_index :recipients, [:account_id, :uuid], :name => "by_account_uuid"
  end

  def self.down
    remove_index :recipients, :name => "by_account_type"
    remove_index :recipients, :name => "by_account_uuid"
  end
end
