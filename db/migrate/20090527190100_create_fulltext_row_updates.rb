class CreateFulltextRowUpdates < ActiveRecord::Migration
  def self.up
    create_table :fulltext_row_updates do |t|
      t.column :subject_type, :string
      t.column :subject_id, :integer
      t.column :account_id, :integer
      t.column :deletion, :boolean, :default => false
    end
  end

  def self.down
    drop_table :fulltext_row_updates
  end
end
