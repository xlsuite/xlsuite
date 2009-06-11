class CreateProductGrants < ActiveRecord::Migration
  def self.up
    create_table :product_grants do |t|
      t.column :product_id, :integer
      t.column :object_id, :integer
      t.column :object_type, :string
      t.column :id, :integer
    end
  end

  def self.down
    drop_table :product_grants
  end
end
