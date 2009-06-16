class AddingIndexByAuthorAndPublishedAtInBlogPosts < ActiveRecord::Migration
  def self.up
    add_index :blog_posts, [:author_id, :published_at], :name => "by_author_published_at"
  end

  def self.down
    remove_index :blog_posts, :name => "by_author_published_at"
  end
end
