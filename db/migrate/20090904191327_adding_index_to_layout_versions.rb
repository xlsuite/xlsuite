class AddingIndexToLayoutVersions < ActiveRecord::Migration
  def self.up
    add_index :layout_versions, [:layout_id, :version], :name => "by_layout_version"
  end

  def self.down
    remove_index :layout_versions, :name => "by_layout_version"
  end
end
