class CreatingPartiesProductCategories < ActiveRecord::Migration
  def self.up
    create_table(:parties_product_categories, :id => false) do |t|
      t.column :party_id, :integer
      t.column :product_category_id, :integer
    end
  end

  def self.down
    drop_table :parties_product_categories
  end
end
