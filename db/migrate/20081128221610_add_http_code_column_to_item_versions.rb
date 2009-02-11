class AddHttpCodeColumnToItemVersions < ActiveRecord::Migration
  def self.up
    add_column :item_versions, :http_code, :integer, :default => 200
  end

  def self.down
    remove_column :item_versions, :http_code
  end
end
