class AddingSourcePartyIdAndDomainIdInAffiliateAccounts < ActiveRecord::Migration
  def self.up
    add_column :affiliate_accounts, :source_party_id, :integer
    add_column :affiliate_accounts, :source_domain_id, :integer
  end

  def self.down
    remove_column :affiliate_accounts, :source_party_id
    remove_column :affiliate_accounts, :source_domain_id
  end
end
