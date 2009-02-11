class CreateSubscriptions < ActiveRecord::Migration
  def self.up
    create_table :subscriptions do |t|
      t.column :next_renewal_at, :datetime
      t.column :renewal_period_unit, :string
      t.column :renewal_period_length, :integer
      t.column :account_id, :integer
      t.column :payer_id, :integer
      t.column :subject_type, :string
      t.column :subject_id, :integer
      t.column :authorization_code, :string
      t.column :payment_method, :string
      t.timestamps
    end
  end

  def self.down
    drop_table :subscriptions
  end
end
