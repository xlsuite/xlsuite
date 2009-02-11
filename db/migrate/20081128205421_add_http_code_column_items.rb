class AddHttpCodeColumnItems < ActiveRecord::Migration
  def self.up
    add_column :items, :http_code, :integer, :default => 200
  end

  def self.down
    remove_column :items, :http_code
  end
end
