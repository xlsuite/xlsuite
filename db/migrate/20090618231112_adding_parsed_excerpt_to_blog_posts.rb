class AddingParsedExcerptToBlogPosts < ActiveRecord::Migration
  def self.up
    add_column :blog_posts, :parsed_excerpt, :text
  end

  def self.down
    remove_column :blog_posts, :parsed_excerpt
  end
end
