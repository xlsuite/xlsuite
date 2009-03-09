class AddingIndexByBlogIdPublishedAtUpdatedAtOnBlogPosts < ActiveRecord::Migration
  def self.up
    add_index :blog_posts, [:blog_id, :published_at, :updated_at], :name => "by_blog_id_published_at_updated_at"
  end

  def self.down
    remove_index :blog_posts, :name => "by_blog_id_published_at_updated_at"
  end
end
