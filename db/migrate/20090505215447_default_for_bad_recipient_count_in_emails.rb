class DefaultForBadRecipientCountInEmails < ActiveRecord::Migration
  def self.up
    change_column :emails, :bad_recipient_count, :integer, :default => 0
  end

  def self.down
    change_column :emails, :bad_recipient_count, :integer, :default => nil
  end
end
