class SetAccountCurrentTotalAssetSize < ActiveRecord::Migration
  def self.up
    Account.all.each do |acct|
      sum = acct.assets.sum('size')
      acct.update_attribute("current_total_asset_size", sum)
    end
  end

  def self.down
  end
end
