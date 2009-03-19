class AddReferralsPointToPartyDomainPoints < ActiveRecord::Migration
  def self.up
    add_column :party_domain_points, :referrals_point, :integer, :default => 0
  end

  def self.down
    remove_column :party_domain_points, :referrals_point
  end
end
