class AddingIndexOnFulltextRowUpdates < ActiveRecord::Migration
  def self.up
    add_index :fulltext_row_updates, [:subject_type, :subject_id], :name => "by_subject"
  end

  def self.down
    remove_index :fulltext_row_updates, :name => "by_subject"
  end
end
