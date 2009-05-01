class ChangeAccountTotalAssetSizeColumnsToLongInt < ActiveRecord::Migration
  def self.up
    change_column :accounts, :cap_total_asset_size, :bigint
    change_column :accounts, :current_total_asset_size, :bigint
  end

  def self.down
    change_column :accounts, :cap_total_asset_size, :integer
    change_column :accounts, :current_total_asset_size, :integer
  end
end
