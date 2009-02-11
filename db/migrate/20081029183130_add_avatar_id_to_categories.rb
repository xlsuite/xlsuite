class AddAvatarIdToCategories < ActiveRecord::Migration
  def self.up
    add_column :categories, :avatar_id, :integer
  end

  def self.down
    remove_column :categories, :avatar_id
  end
end
