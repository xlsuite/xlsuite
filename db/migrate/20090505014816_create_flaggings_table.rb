class CreateFlaggingsTable < ActiveRecord::Migration
  def self.up
    create_table :flaggings do |t|
      t.column :account_id, :integer
      t.column :created_by_id, :integer
      t.column :request_ip, :string
      t.column :flaggable_type, :string
      t.column :flaggable_id, :integer
      t.column :reason, :text
      t.column :created_at, :datetime
      t.column :approved_at, :datetime
      t.column :referrer_url, :string
    end
  end

  def self.down
    drop_table :flaggings
  end
end
