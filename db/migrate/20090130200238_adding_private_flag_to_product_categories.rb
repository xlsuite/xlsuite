class AddingPrivateFlagToProductCategories < ActiveRecord::Migration
  def self.up
    add_column :product_categories, :private, :boolean, :default => false
  end

  def self.down
    remove_column :product_categories, :private
  end
end
