class AddEnabledToEmailAccounts < ActiveRecord::Migration
  def self.up
    add_column :email_accounts, :enabled, :boolean, :default => false
  end

  def self.down
    remove_column :email_accounts, :enabled
  end
end
