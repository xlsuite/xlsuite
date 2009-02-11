class AddingFeeRelatedColumnsToInstalledAccountTemplates < ActiveRecord::Migration
  def self.up
    add_column :installed_account_templates, :setup_fee_cents, :integer
    add_column :installed_account_templates, :setup_fee_currency, :string
    add_column :installed_account_templates, :subscription_markup_fee_cents, :integer
    add_column :installed_account_templates, :subscription_markup_fee_currency, :string
    add_column :installed_account_templates, :minimum_subscription_fee_cents, :integer
    add_column :installed_account_templates, :minimum_subscription_fee_currency, :string
  end

  def self.down
    %w(setup_fee subscription_markup_fee minimum_subscription_fee).each do |fee_name|
      remove_column :installed_account_templates, (fee_name + "_cents").to_sym
      remove_column :installed_account_templates, (fee_name + "_currency").to_sym
    end
  end
end
