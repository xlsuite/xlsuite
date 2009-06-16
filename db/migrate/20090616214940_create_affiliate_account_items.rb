class CreateAffiliateAccountItems < ActiveRecord::Migration
  def self.up
    create_table :affiliate_account_items do |t|
      t.column :affiliate_account_id, :integer
      t.column :level, :integer, :default => 0
      t.column :target_type, :string
      t.column :target_id, :integer
      t.timestamps
    end
  end

  def self.down
    drop_table :affiliate_account_items
  end
end
