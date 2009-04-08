class CreateSharedEmailAccounts < ActiveRecord::Migration
  def self.up
    create_table :shared_email_accounts do |t|
      t.column :email_account_id, :integer
      t.column :target_type, :string
      t.column :target_id, :integer
    end
  end

  def self.down
    drop_table :shared_email_accounts
  end
end
