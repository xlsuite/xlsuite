class CreateDomainAvailableItems < ActiveRecord::Migration
  def self.up
    create_table :domain_available_items do |t|
      t.column :account_id, :integer
      t.column :domain_id, :integer
      t.column :item_type, :string
      t.column :item_id, :integer
      t.column :created_at, :datetime
    end
    
    add_index :domain_available_items, [:domain_id, :item_type, :item_id], :name => "by_domain_item_type_item_id"
  end

  def self.down
    drop_table :domain_available_items
  end
end
