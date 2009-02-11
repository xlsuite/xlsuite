class RemovingPublicColumnFromGroups < ActiveRecord::Migration
  def self.up
    remove_column :groups, :public
  end

  def self.down
    add_column :groups, :public, :boolean, :default => false
  end
end
