class AddAddPartyToDatabaseColumnToContactRequest < ActiveRecord::Migration
  def self.up
    add_column :contact_requests, :add_party_to_database, :boolean, :default => true
  end

  def self.down
    remove_column :contact_requests, :add_party_to_database
  end
end
