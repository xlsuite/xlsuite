class AddReferralDomainToAccount < ActiveRecord::Migration
  def self.up
    add_column :accounts, :referral_domain, :string
  end

  def self.down
    remove_column :accounts, :referral_domain
  end
end
