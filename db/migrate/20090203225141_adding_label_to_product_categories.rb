class AddingLabelToProductCategories < ActiveRecord::Migration
  def self.up
    add_column :product_categories, :label, :string
  end

  def self.down
    remove_column :product_categories, :label
  end
end
