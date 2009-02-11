class CreateAccountModuleSubscriptions < ActiveRecord::Migration
  def self.up
    create_table :account_module_subscriptions do |t|
      t.column :account_id, :integer
      t.column :payment_id, :integer
      t.column :minimum_subscription_fee_cents, :integer
      t.column :minimum_subscription_fee_currency, :string
      t.column :options, :text
      t.timestamps
    end
  end

  def self.down
    drop_table :account_module_subscriptions
  end
end
