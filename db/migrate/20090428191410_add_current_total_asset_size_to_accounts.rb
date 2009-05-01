class AddCurrentTotalAssetSizeToAccounts < ActiveRecord::Migration
  def self.up
    add_column :accounts, :current_total_asset_size, :integer
  end

  def self.down
    remove_column :accounts, :current_total_asset_size
  end
end
