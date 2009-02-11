class AddingOwnerIdToProducts < ActiveRecord::Migration
  def self.up
    add_column :products, :owner_id, :integer
  end

  def self.down
    remove_column :products, :owner_id
  end
end
