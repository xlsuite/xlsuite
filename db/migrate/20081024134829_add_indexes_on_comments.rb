class AddIndexesOnComments < ActiveRecord::Migration
  def self.up
    add_index :comments, %w(commentable_type commentable_id), :name => :by_commentable
    add_index :comments, %w(account_id commentable_type commentable_id), :name => :by_account
  end

  def self.down
    remove_index :comments, :name => :by_commentable
    remove_index :comments, :name => :by_account
  end
end
