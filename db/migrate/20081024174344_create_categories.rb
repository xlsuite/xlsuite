class CreateCategories < ActiveRecord::Migration
  def self.up
    create_table :categories do |t|
      t.column :account_id, :integer
      t.column :name, :string
      t.column :label, :string
      t.timestamps
    end
  end

  def self.down
    drop_table :categories
  end
end
