class AddPrivateFlagToBlogs < ActiveRecord::Migration
  def self.up
    add_column :blogs, :private, :boolean, :default => false
  end

  def self.down
    remove_column :blogs, :private
  end
end
