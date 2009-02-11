class AddObjectAndGroupIndexToAuthorizations < ActiveRecord::Migration
  def self.up
    add_index :authorizations, [:object_type, :object_id, :group_id], :name => "by_object_and_group"
  end

  def self.down
    remove_index :authorizations, :name => "by_object_and_group"
  end
end
