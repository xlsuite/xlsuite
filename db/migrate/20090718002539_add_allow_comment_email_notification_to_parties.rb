class AddAllowCommentEmailNotificationToParties < ActiveRecord::Migration
  def self.up
    add_column :parties, :profile_comment_notification, :boolean, :default => true
    add_column :parties, :blog_post_comment_notification, :boolean, :default => true
    add_column :parties, :listing_comment_notification, :boolean, :default => true
    add_column :parties, :product_comment_notification, :boolean, :default => true
  end

  def self.down
    remove_column :parties, :profile_comment_notification
    remove_column :parties, :blog_post_comment_notification
    remove_column :parties, :listing_comment_notification
    remove_column :parties, :product_comment_notification
  end
end
