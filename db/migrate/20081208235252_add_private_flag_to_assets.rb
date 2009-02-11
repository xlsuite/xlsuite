class AddPrivateFlagToAssets < ActiveRecord::Migration
  def self.up
    add_column :assets, :private, :boolean, :default => false
  end

  def self.down
    remove_column :assets, :private
  end
end
