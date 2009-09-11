class CreateActionHandlerPartyCompletedSequences < ActiveRecord::Migration
  def self.up
    create_table :action_handler_party_completed_sequences do |t|
      t.column :domain_id, :integer
      t.column :account_id, :integer
      t.column :party_id, :integer
      t.column :action_handler_sequence_id, :integer
      t.column :last_ran_at, :datetime
      t.column :ran_counter, :integer
      t.column :created_at, :datetime
    end
  end

  def self.down
    drop_table :action_handler_party_completed_sequences
  end
end
