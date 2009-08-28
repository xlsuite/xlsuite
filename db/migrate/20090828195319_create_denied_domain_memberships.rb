class CreateDeniedDomainMemberships < ActiveRecord::Migration
  def self.up
    create_table :denied_domain_memberships do |t|
      t.column :domain_id, :integer
      t.column :group_id, :integer
      t.column :party_id, :integer
      t.column :created_at, :datetime
    end
    
    add_index :denied_domain_memberships, [:domain_id, :group_id, :party_id], :name => "by_domain_group_party"
    add_index :denied_domain_memberships, [:domain_id, :group_id], :name => "by_domain_group"
    add_index :denied_domain_memberships, [:group_id, :party_id], :name => "by_group_party"
  end

  def self.down
    drop_table :denied_domain_memberships
  end
end
