class AddingFlagsToAccountTemplates < ActiveRecord::Migration
  def self.up
    add_column :account_templates, :f_blogs, :boolean, :default => false
    add_column :account_templates, :f_directories, :boolean, :default => false
    add_column :account_templates, :f_forums, :boolean, :default => false
    add_column :account_templates, :f_product_catalog, :boolean, :default => false
    add_column :account_templates, :f_profiles, :boolean, :default => false
    add_column :account_templates, :f_real_estate_listings, :boolean, :default => false
    add_column :account_templates, :f_rss_feeds, :boolean, :default => false
    add_column :account_templates, :f_testimonials, :boolean, :default => false
  end

  def self.down
    remove_column :account_templates, :f_blogs
    remove_column :account_templates, :f_directories
    remove_column :account_templates, :f_forums
    remove_column :account_templates, :f_product_catalog
    remove_column :account_templates, :f_profiles
    remove_column :account_templates, :f_real_estate_listings
    remove_column :account_templates, :f_rss_feeds
    remove_column :account_templates, :f_testimonials
  end
end
