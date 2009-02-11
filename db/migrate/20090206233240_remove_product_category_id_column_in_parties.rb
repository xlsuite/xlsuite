class RemoveProductCategoryIdColumnInParties < ActiveRecord::Migration
  def self.up
    remove_column :parties, :product_category_id
  end

  def self.down
    add_column :parties, :product_category_id, :integer
  end
end
