class CreateProfileRequestsTable < ActiveRecord::Migration
  def self.up
    create_table :profile_requests do |t|
      t.column :first_name, :string
      t.column :middle_name, :string
      t.column :last_name, :string
      t.column :company_name, :string
      t.column :position, :string
      t.column :honorific, :string
      t.column :avatar_id, :integer
      t.column :created_at, :datetime
      t.column :account_id, :integer
      t.column :info, :text
      t.column :type, :string
      t.column :approved_at, :datetime
      t.column :profile_id, :integer
      t.column :created_by_id, :integer
    end
  end

  def self.down
    drop_table :profile_requests
  end
end
