class AddAccountIdPrivateIndexToBlogs < ActiveRecord::Migration
  def self.up
    add_index :blogs, [:account_id, :private], :name => "by_account_private"
  end

  def self.down
    remove_index :blogs, :name => "by_account_private"
  end
end
