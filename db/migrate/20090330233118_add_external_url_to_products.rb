class AddExternalUrlToProducts < ActiveRecord::Migration
  def self.up
    add_column :products, :external_url, :string, :limit => 1024
  end

  def self.down
    remove_column :products, :external_url
  end
end
