class AddingSmtpEmailAccountIdToEmails < ActiveRecord::Migration
  def self.up
    add_column :emails, :smtp_email_account_id, :integer
  end

  def self.down
    remove_column :emails, :smtp_email_account_id
  end
end
