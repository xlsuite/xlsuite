class CreateCachedPages < ActiveRecord::Migration
  def self.up
    create_table :cached_pages do |t|
      t.column :uri, :string, :limit => 1024
      t.column :account_id, :integer
      t.column :domain_id, :integer
      t.column :page_id, :integer
      t.column :page_fullslug, :string, :limit => 256
      t.column :visit_num, :integer, :default => 0
      t.column :cap_visit_num, :integer, :default => 5
      t.column :next_refresh_at, :datetime
      t.column :refresh_period_in_seconds, :integer, :default => 54000
      t.column :rendered_content, :mediumblob
      t.column :rendered_content_type, :string
      t.column :last_refreshed_at, :datetime
      t.column :css, :boolean, :default =>  false
      t.column :javascript, :boolean, :default => false
      t.timestamps
    end
    
    add_index :cached_pages, [:account_id, :domain_id, :uri], :name => "by_account_domain_uri"
    add_index :cached_pages, [:account_id, :domain_id, :uri, :last_refreshed_at], :name => "by_account_domain_uri_last_refreshed"
    add_index :cached_pages, :next_refresh_at, :name => "by_next_refresh_at"
    add_index :cached_pages, :visit_num, :name => "by_visit_num"
  end

  def self.down
    drop_table :cached_pages
  end
end
