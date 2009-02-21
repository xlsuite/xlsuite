class AddingNoUpdateToLayoutVersions < ActiveRecord::Migration
  def self.up
    add_column :layout_versions, :no_update, :boolean, :default => false
  end

  def self.down
    remove_column :layout_versions, :no_update
  end
  
  class LayoutVersion < ActiveRecord::Base; end
end
