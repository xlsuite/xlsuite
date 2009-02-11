class AddPartyIdIndexToMemberships < ActiveRecord::Migration
  def self.up
    add_index :memberships, [:party_id], :name => "by_party"
  end

  def self.down
    remove_index :memberships, :name => "by_party"
  end
end
