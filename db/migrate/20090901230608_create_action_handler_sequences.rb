class CreateActionHandlerSequences < ActiveRecord::Migration
  def self.up
    create_table :action_handler_sequences do |t|
      t.column :action_type, :string
      t.column :action_args, :text
      t.column :position, :integer
      t.column :conditions, :text
      t.column :description, :text
      t.column :action_handler_id, :integer
      t.column :repeat_period_length, :integer
      t.column :repeat_period_unit, :string
      t.column :after_period_length, :integer
      t.column :after_period_unit, :string
      t.column :time_reference, :string
    end
    
    add_index :action_handler_sequences, :action_handler_id, :name => "by_action_handler"
  end

  def self.down
    drop_table :action_handler_sequences
  end
end
