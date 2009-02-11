class CreateCategorizables < ActiveRecord::Migration
  def self.up
    create_table :categorizables do |t|
      t.column :category_id, :integer
      t.column :subject_type, :string
      t.column :subject_id, :integer
      t.column :created_at, :datetime
    end
  end

  def self.down
    drop_table :categorizables
  end
end
