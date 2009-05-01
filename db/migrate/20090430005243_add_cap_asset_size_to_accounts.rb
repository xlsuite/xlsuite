class AddCapAssetSizeToAccounts < ActiveRecord::Migration
  def self.up
    add_column :accounts, :cap_asset_size, :integer, :default => 8.megabytes
  end

  def self.down
    remove_column :accounts, :cap_asset_size
  end
end
