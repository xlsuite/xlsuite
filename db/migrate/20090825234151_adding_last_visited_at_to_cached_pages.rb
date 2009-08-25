class AddingLastVisitedAtToCachedPages < ActiveRecord::Migration
  def self.up
    add_column :cached_pages, :last_visited_at, :datetime
  end

  def self.down
    remove_column :cached_pages, :last_visited_at
  end
end
