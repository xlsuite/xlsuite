class AddBlogPublishedIndexToBlogPosts < ActiveRecord::Migration
  def self.up
    add_index :blog_posts, [:blog_id, :published_at], :name => "by_blog_published_at"
  end

  def self.down
    remove_index :blog_posts, :name => "by_blog_published_at"
  end
end
