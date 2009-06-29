class AddColumnConfirmedToParties < ActiveRecord::Migration
  def self.up
    add_column :parties, :confirmed, :boolean, :default => false
    Party.update_all("confirmed = 1", "confirmed_at IS NOT NULL")
  end

  def self.down
    remove_column :parties, :confirmed
  end
end
