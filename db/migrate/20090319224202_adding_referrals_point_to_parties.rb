class AddingReferralsPointToParties < ActiveRecord::Migration
  def self.up
    add_column :parties, :referrals_point, :integer, :default => 0
  end

  def self.down
    remove_column :parties, :referrals_point
  end
end
