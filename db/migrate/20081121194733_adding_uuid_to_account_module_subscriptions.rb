class AddingUuidToAccountModuleSubscriptions < ActiveRecord::Migration
  def self.up
    add_column :account_module_subscriptions, :uuid, :string, :limit => 36
  end

  def self.down
    remove_column :account_module_subscriptions, :uuid
  end
end
