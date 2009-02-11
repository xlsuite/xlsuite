class CreateExpiringPartyItems < ActiveRecord::Migration
  def self.up
    create_table :expiring_party_items do |t|
      t.column :item_type, :string
      t.column :item_id, :integer
      t.column :party_id, :integer
      t.column :updated_by_type, :string
      t.column :updated_by_id, :integer
      t.column :created_by_type, :string
      t.column :created_by_id, :integer
      t.timestamps
    end
  end

  def self.down
    drop_table :expiring_party_items
  end
end
