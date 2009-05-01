class AddDefaultToAccountCurrentTotalAssetSize < ActiveRecord::Migration
  def self.up
    change_column :accounts, :current_total_asset_size, :bigint, :default => 0
  end

  def self.down
    change_column :accounts, :current_total_asset_size, :bigint
  end
end
