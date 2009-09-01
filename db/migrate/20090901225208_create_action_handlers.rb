class CreateActionHandlers < ActiveRecord::Migration
  def self.up
    create_table :action_handlers do |t|
      t.column :account_id, :integer
      t.column :name, :string
      t.column :label, :string
      t.column :description, :text
      t.column :last_checked_at, :datetime
      t.column :activated_at, :datetime
      t.column :deactivated_at, :datetime
      t.timestamps
    end
    
    add_index :action_handlers, [:account_id, :label], :name => "by_account_label"
    add_index :action_handlers, [:last_checked_at, :activated_at, :deactivated_at], :name => "by_last_checked_activated_deactivated_at" 
  end

  def self.down
    drop_table :action_handlers
  end
end
