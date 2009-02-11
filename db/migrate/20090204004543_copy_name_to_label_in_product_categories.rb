class CopyNameToLabelInProductCategories < ActiveRecord::Migration
  def self.up
    ProductCategory.update_all("label=name")
  end

  def self.down
    ProductCategory.update_all("label=NULL")
  end
end
