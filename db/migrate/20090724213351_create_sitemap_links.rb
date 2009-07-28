class CreateSitemapLinks < ActiveRecord::Migration
  def self.up
    create_table :sitemap_links do |t|
      t.column :domain_id, :integer
      t.column :url, :string, :limit => 2048
      t.timestamps
    end
    add_index :sitemap_links, [:domain_id, :url], :by => "by_domain_url"
  end

  def self.down
    drop_table :sitemap_links
  end
end
