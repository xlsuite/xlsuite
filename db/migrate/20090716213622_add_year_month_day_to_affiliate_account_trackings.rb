class AddYearMonthDayToAffiliateAccountTrackings < ActiveRecord::Migration
  def self.up
    add_column :affiliate_account_trackings, :year, :integer
    add_column :affiliate_account_trackings, :month, :integer
    add_column :affiliate_account_trackings, :day, :integer
  end

  def self.down
    remove_column :affiliate_account_trackings, :year
    remove_column :affiliate_account_trackings, :month
    remove_column :affiliate_account_trackings, :day
  end
end
