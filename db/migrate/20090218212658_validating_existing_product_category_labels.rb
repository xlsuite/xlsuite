class ValidatingExistingProductCategoryLabels < ActiveRecord::Migration
  def self.up
    ProductCategory.all.each do |product_category|
      product_category.label = product_category.label.downcase.gsub(/[^\w\s-]/, "").gsub(/\s+/, "_")
      product_category.save!
    end
  end

  def self.down
  end
  
  class ProductCategory < ActiveRecord::Base
    validates_uniqueness_of :label, :scope => :account_id
    validates_format_of :label, :with => /\A[-\w]+\Z/i, :message => "can contain only a-z, A-Z, 0-9, _ and -, cannot contain space(s)"    
  end
end
