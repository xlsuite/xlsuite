class AddStartedAtAndExpiredAtToExpiringPartyItems < ActiveRecord::Migration
  def self.up
    add_column :expiring_party_items, :started_at, :datetime
    add_column :expiring_party_items, :expired_at, :datetime
  end

  def self.down
    remove_column :expiring_party_items, :started_at
    remove_column :expiring_party_items, :expired_at
  end
end
