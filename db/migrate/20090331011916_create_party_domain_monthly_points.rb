class CreatePartyDomainMonthlyPoints < ActiveRecord::Migration
  def self.up
    create_table :party_domain_monthly_points do |t|
      t.column :account_id, :integer
      t.column :domain_id, :integer
      t.column :party_id, :integer
      t.column :own_point, :integer, :default => 0
      t.column :referrals_point, :integer, :default => 0
      t.column :year, :integer, :limit => 2
      t.column :month, :integer, :limit => 1
      t.column :updated_at, :datetime
    end
  end

  def self.down
    drop_table :party_domain_monthly_points
  end
end
