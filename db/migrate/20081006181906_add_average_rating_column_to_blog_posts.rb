class AddAverageRatingColumnToBlogPosts < ActiveRecord::Migration
  def self.up
    add_column :blog_posts, :average_rating, :decimal, :precision => 5, :scale => 3, :default => 0, :null => false
  end

  def self.down
    remove_column :blog_posts, :average_rating
  end
end
