class AddRefreshRequestedToCachedPages < ActiveRecord::Migration
  def self.up
    add_column :cached_pages, :refresh_requested, :boolean, :default => false
  end

  def self.down
    remove_column :cached_pages, :refresh_requested
  end
end
