class InitializeBadRecipientCountInEmails < ActiveRecord::Migration
  def self.up
    Email.update_all("bad_recipient_count = 0", "bad_recipient_count IS NULL")
  end

  def self.down
  end
end
