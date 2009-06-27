class ChangePartyConfirmedToConfirmedAt < ActiveRecord::Migration
  def self.up
    add_column :parties, :confirmed_at, :datetime
    Party.update_all("confirmed_at = created_at", "confirmed = 1")
    remove_column :parties, :confirmed
  end

  def self.down
    add_column :parties, :confirmed, :boolean, :default => false
    Party.update_all("confirmed = 1", "confirmed_at IS NOT NULL")
    remove_column :parties, :confirmed_at
  end
end
