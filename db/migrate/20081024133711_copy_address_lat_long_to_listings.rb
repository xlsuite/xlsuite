class CopyAddressLatLongToListings < ActiveRecord::Migration
  def self.up
    execute "UPDATE listings l INNER JOIN contact_routes cr ON cr.routable_id = l.id AND cr.routable_type = 'Listing' SET l.latitude = cr.latitude, l.longitude = cr.longitude"
  end

  def self.down
    execute "UPDATE listings SET latitude = NULL, longitude = NULL"
  end
end
