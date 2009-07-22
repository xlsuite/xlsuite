class AddSentEmailNotificationFlagToComments < ActiveRecord::Migration
  def self.up
    add_column :comments, :sent_email_notification, :boolean, :default => false
    Comment.update_all("sent_email_notification = 1", "spam = 0 AND approved_at IS NOT NULL")
  end

  def self.down
    remove_column :comments, :sent_email_notification
  end
end
