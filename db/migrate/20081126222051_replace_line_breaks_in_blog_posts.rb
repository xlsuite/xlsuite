class ReplaceLineBreaksInBlogPosts < ActiveRecord::Migration
  def self.up
    BlogPost.all.each do |post|
      post.update_attribute("body", post.body.gsub("<br>", "<br />")) unless post.body.blank?
    end
  end

  def self.down
  end
end