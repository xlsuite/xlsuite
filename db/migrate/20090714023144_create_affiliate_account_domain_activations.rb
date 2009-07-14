class CreateAffiliateAccountDomainActivations < ActiveRecord::Migration
  def self.up
    create_table :affiliate_account_domain_activations do |t|
      t.column :affiliate_account_id, :integer
      t.column :domain_id, :integer
      t.column :created_at, :datetime
    end
  end

  def self.down
    drop_table :affiliate_account_domain_activations
  end
end
