class AddingSubjectIndexToCategorizables < ActiveRecord::Migration
  def self.up
    add_index :categorizables, [:subject_type, :subject_id], :name => "by_subject"
  end

  def self.down
    remove_index :categorizables, :name => 'by_subject'
  end
end
