class AddingIndexToLayoutVersions < ActiveRecord::Migration
  def self.up
    add_index :layout_versions, :layout_id, :name => "by_layout"
  end

  def self.down
    remove_index :layout_versions, :name => "by_layout"
  end
end
