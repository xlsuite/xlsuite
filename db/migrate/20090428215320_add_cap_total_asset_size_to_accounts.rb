class AddCapTotalAssetSizeToAccounts < ActiveRecord::Migration
  def self.up
    add_column :accounts, :cap_total_asset_size, :integer, :default => 200.megabytes
  end

  def self.down
    remove_column :accounts, :cap_total_asset_size
  end
end
