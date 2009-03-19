class CreatePartyDomainPoints < ActiveRecord::Migration
  def self.up
    create_table :party_domain_points do |t|
      t.column :account_id, :integer
      t.column :domain_id, :integer
      t.column :party_id, :integer
      t.column :point, :integer, :default => 0
    end
  end

  def self.down
    drop_table :party_domain_points
  end
end
