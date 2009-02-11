class AddingNumberColumnToAccountModuleSubscriptions < ActiveRecord::Migration
  def self.up
    add_column :account_module_subscriptions, :number, :string
  end

  def self.down
    remove_column :account_module_subscriptions, :number
  end
end
