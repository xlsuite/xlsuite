class CreateProductItems < ActiveRecord::Migration
  def self.up
    create_table :product_items do |t|
      t.column :item_type, :string
      t.column :item_id, :integer
      t.column :product_id, :integer
    end
  end

  def self.down
    drop_table :product_items
  end
end
