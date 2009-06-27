class AddingDomainIdToAffiliateAccountItems < ActiveRecord::Migration
  def self.up
    add_column :affiliate_account_items, :domain_id, :integer
  end

  def self.down
    remove_column :affiliate_account_items, :domain_id, :integer
  end
end
