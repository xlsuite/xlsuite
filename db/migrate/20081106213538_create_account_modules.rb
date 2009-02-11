class CreateAccountModules < ActiveRecord::Migration
  def self.up
    create_table :account_modules do |t|
      t.column :account_id, :integer
      t.column :module, :string
      t.column :minimum_price_cents, :integer
      t.column :minimum_price_currency, :string
      t.timestamps
    end
  end

  def self.down
    drop_table :account_modules
  end
end
