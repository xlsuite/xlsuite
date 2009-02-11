class SetGroupNameOnGoogleMapsApiKey < ActiveRecord::Migration
  def self.up
    Configuration.update_all(["group_name = ?", "Google Maps"], ["group_name IS NULL AND name = ?", "google_maps_api_key"])
  end

  def self.down
  end
end
