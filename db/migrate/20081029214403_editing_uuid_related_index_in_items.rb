class EditingUuidRelatedIndexInItems < ActiveRecord::Migration
  def self.up
    remove_index :items, :name => :by_guid
    add_index :items, [:account_id, :uuid], :name => :by_account_uuid, :unique => true
  end

  def self.down
    remove_index :items, :name => :by_account_uuid
    add_index :items, [:uuid], :name => :by_guid, :unique => true
  end
end
