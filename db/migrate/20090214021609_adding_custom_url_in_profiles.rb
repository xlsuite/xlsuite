class AddingCustomUrlInProfiles < ActiveRecord::Migration
  def self.up
    add_column :profiles, :custom_url, :string
  end

  def self.down
    remove_column :profiles, :custom_url
  end
end
