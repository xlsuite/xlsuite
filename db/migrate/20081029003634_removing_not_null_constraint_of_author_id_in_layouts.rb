class RemovingNotNullConstraintOfAuthorIdInLayouts < ActiveRecord::Migration
  def self.up
    change_column :layouts, :author_id, :integer, :null => true
  end

  def self.down
    change_column :layouts, :author_id, :integer, :null => false
  end
end
