class CreateActionHandlers < ActiveRecord::Migration
  def self.up
    create_table :action_handlers do |t|
      t.column :account_id, :integer
      t.column :name, :string
      t.column :label, :string
      t.column :description, :text
      t.column :last_checked_at, :datetime
      t.timestamps
    end
  end

  def self.down
    drop_table :action_handlers
  end
end
