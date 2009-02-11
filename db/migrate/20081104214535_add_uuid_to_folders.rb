class AddUuidToFolders < ActiveRecord::Migration
  def self.up
    add_column :folders, :uuid, :string, :limit => 36
    Folder.update_all("uuid = UUID()")
  end

  def self.down
    remove_column :folders, :uuid
  end
  
  class Folder < ActiveRecord::Base; end
end
