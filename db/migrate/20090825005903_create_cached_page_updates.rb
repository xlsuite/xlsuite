class CreateCachedPageUpdates < ActiveRecord::Migration
  def self.up
    create_table :cached_page_updates do |t|
      t.column :cached_page_id, :integer
      t.column :domain_id, :integer
      t.column :started_at, :datetime
    end
    
    add_index :cached_page_updates, :cached_page_id, :name => "by_cached_page"
    add_index :cached_page_updates, [:domain_id, :started_at], :name => "by_domain_started_at"
  end

  def self.down
    drop_table :cached_page_updates
  end
end
