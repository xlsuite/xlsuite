class AddPublicFlagToGroups < ActiveRecord::Migration
  def self.up
    add_column :groups, :public, :boolean, :default => false
  end

  def self.down
    remove_column :groups, :public
  end
end
