class EditingInstalledAccountTemplates < ActiveRecord::Migration
  def self.up
    remove_column :installed_account_templates, :minimum_subscription_fee_cents
    remove_column :installed_account_templates, :minimum_subscription_fee_currency
    add_column :installed_account_templates, :account_module_subscription_id, :integer
  end

  def self.down
    add_column :installed_account_templates, :minimum_subscription_fee_cents, :integer
    add_column :installed_account_templates, :minimum_subscription_fee_currency, :string
    remove_column :installed_account_templates, :account_module_subscription_id
  end
end
