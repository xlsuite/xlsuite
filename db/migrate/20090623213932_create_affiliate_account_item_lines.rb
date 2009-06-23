class CreateAffiliateAccountItemLines < ActiveRecord::Migration
  def self.up
    create_table :affiliate_account_item_lines do |t|
      t.column :affiliate_account_item_id, :integer
      t.column :target_type, :string
      t.column :target_id, :integer
      t.column :price_cents, :integer
      t.column :price_currency, :string
      t.column :commission_percentage, :decimal, :precision => 5, :scale => 2
      t.column :commission_cents, :integer
      t.column :commission_currency, :string
      t.column :subscription, :boolean
      t.timestamps
    end
  end

  def self.down
    drop_table :affiliate_account_item_lines
  end
end
