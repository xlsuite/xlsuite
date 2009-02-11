class AddClaimableAndOwnerIdColumnsToProfile < ActiveRecord::Migration
  def self.up
    add_column :profiles, :claimable, :boolean, :default => false
    add_column :profiles, :owner_id, :integer
  end

  def self.down
    remove_column :profiles, :claimable
    remove_column :profiles, :owner_id
  end
end
