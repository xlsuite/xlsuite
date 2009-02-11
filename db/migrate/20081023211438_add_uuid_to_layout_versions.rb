class AddUuidToLayoutVersions < ActiveRecord::Migration
  def self.up
    add_column :layout_versions, :uuid, :string, :limit => 36
  end

  def self.down
    remove_column :layout_versions, :uuid
  end
end
