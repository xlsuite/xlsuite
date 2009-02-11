class CreateAccountTemplates < ActiveRecord::Migration
  def self.up
    create_table :account_templates do |t|
      t.column :account_id, :integer, :default => 1
      t.column :trunk_account_id, :integer
      t.column :stable_account_id, :integer
      t.column :name, :string
      t.column :demo_url, :string
      t.column :setup_fee_cents, :integer
      t.column :setup_fee_currencey, :string
      t.column :period_fee_cents, :integer
      t.column :period_fee_currency, :string
      t.column :period_length, :integer
      t.column :period_duration, :string
      t.column :approved_at, :datetime
      t.column :approved_by_id, :integer
      t.column :previous_stables, :text
      t.timestamps
    end
  end

  def self.down
    drop_table :account_templates
  end
end
