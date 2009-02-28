class AddConfirmationUrlColumnToProfileRequests < ActiveRecord::Migration
  def self.up
    add_column :profile_requests, :confirmation_url, :string
  end

  def self.down
    remove_column :profile_requests, :confirmation_url
  end
end
