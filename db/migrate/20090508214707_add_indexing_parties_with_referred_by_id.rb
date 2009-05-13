class AddIndexingPartiesWithReferredById < ActiveRecord::Migration
  def self.up
    add_index :parties, :referred_by_id, :name => "by_referred_by"
  end

  def self.down
    remove_index :parties, :name => "by_referred_by"
  end
end
