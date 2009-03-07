class AddDomainIdToContactRequests < ActiveRecord::Migration
  def self.up
    add_column :contact_requests, :domain_id, :integer
  end

  def self.down
    remove_column :contact_requests, :domain_id
  end
end
