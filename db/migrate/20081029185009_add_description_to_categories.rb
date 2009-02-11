class AddDescriptionToCategories < ActiveRecord::Migration
  def self.up
    add_column :categories, :description, :text
  end

  def self.down
    remove_column :categories, :description
  end
end
