class NewIndexesForCachedPages < ActiveRecord::Migration
  def self.up
    add_index :cached_pages, :last_visited_at, :name => "by_last_visited_at"
    add_index :cached_pages, [:account_id, :page_fullslug], :name => "by_account_page_fullslug"
  end

  def self.down
    remove_index :cached_pages, :name => "by_last_visited_at"
    remove_index :cached_pages, :name => "by_account_page_fullslug"
  end
end
