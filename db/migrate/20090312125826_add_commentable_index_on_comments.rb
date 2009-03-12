class AddCommentableIndexOnComments < ActiveRecord::Migration
  def self.up
    add_index :comments, %w(commentable_type commentable_id), :name => :by_commentable
  end

  def self.down
    remove_index :comments, :name => :by_commentable
  end
end
