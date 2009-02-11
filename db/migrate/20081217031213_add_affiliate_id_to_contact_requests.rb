class AddAffiliateIdToContactRequests < ActiveRecord::Migration
  def self.up
    add_column :contact_requests, :affiliate_id, :integer
  end

  def self.down
    remove_column :contact_requests, :affiliate_id
  end
end
