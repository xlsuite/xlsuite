class AddingPrivateFlagToProducts < ActiveRecord::Migration
  def self.up
    add_column :products, :private, :boolean, :default => false
  end

  def self.down
    remove_column :products, :private
  end
end
