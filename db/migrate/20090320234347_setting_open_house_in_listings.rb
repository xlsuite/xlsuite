class SettingOpenHouseInListings < ActiveRecord::Migration
  def self.up
    Listing.update_all("open_house=1", "open_house_text IS NOT NULL")
  end

  def self.down
    Listing.update_all("open_house=0")
  end
end
