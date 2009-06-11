class CreateAffiliateAccounts < ActiveRecord::Migration
  def self.up
    create_table :affiliate_accounts do |t|
      t.column :email_address, :string
      t.column :username, :string
      t.column :first_name, :string
      t.column :middle_name, :string
      t.column :last_name, :string
      t.column :honorific, :string, :limit => 5
      t.column :company_name, :string
      t.column :position, :string
      t.column :uuid, :string, :limit => 40
      t.column :password_hash, :string, :limit => 40
      t.column :password_salt, :string, :limit => 40
      t.column :last_logged_in_at, :datetime
      t.column :token, :string
      t.column :token_expires_at, :datetime
      t.column :confirmation_token, :string
      t.column :confirmation_token_expires_at, :datetime
      t.column :own_point, :integer
      t.column :referrals_point, :integer
      t.column :last_referred_by_id, :integer
      t.column :first_referred_by_id, :integer
      t.timestamps
    end
  end

  def self.down
    drop_table :affiliate_accounts
  end
end
