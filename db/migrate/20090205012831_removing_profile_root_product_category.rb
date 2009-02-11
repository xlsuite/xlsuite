class RemovingProfileRootProductCategory < ActiveRecord::Migration
  def self.up
    ProductCategoryConfiguration.all(:conditions => {:name => "profile_root_product_category"}).each do |config|
      pc = config.value
      pc.destroy if pc
    end
    Configuration.delete_all(:name => "profile_root_product_category")
  end

  def self.down
  end
end
