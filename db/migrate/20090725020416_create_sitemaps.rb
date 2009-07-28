class CreateSitemaps < ActiveRecord::Migration
  def self.up
    create_table :sitemaps do |t|
      t.column :domain_id, :integer
      t.column :position, :integer
      t.column :text, :mediumblob
      t.timestamps
    end
    add_index :sitemaps, [:domain_id, :position], :name => "by_domain_position"
  end

  def self.down
    drop_table :sitemaps
  end
end
