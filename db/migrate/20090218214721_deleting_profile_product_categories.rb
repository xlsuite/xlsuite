class DeletingProfileProductCategories < ActiveRecord::Migration
  def self.up
    ProductCategory.all(:conditions => {:label => "profile"}).each do |product_category|
      if product_category.products.count <= 0
        product_category.destroy
      end
    end
  end

  def self.down
  end
end
