class AddDomainIdToBlogPosts < ActiveRecord::Migration
  def self.up
    add_column :blog_posts, :domain_id, :integer
  end

  def self.down
    remove_column :blog_posts, :domain_id, :integer
  end
end
