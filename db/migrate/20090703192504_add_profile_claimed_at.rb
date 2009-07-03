class AddProfileClaimedAt < ActiveRecord::Migration
  def self.up
    add_column :profiles, :claimed_at, :datetime, :default => nil
  end

  def self.down
    remove_column :profiles, :claimed_at
  end
end
