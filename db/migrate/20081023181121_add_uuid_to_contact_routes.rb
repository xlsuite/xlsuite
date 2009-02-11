class AddUuidToContactRoutes < ActiveRecord::Migration
  def self.up
    add_column :contact_routes, :uuid, :string, :limit => 36
    ContactRoute.update_all("uuid = UUID()")
  end

  def self.down
    remove_column :contact_routes, :uuid
  end
  
  class ContactRoute < ActiveRecord::Base; end
end
