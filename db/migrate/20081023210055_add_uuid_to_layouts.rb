class AddUuidToLayouts < ActiveRecord::Migration
  def self.up
    add_column :layouts, :uuid, :string, :limit => 36
    Layout.update_all("uuid = UUID()")
  end

  def self.down
    remove_column :layouts, :uuid
  end
  
  class Layout < ActiveRecord::Base; end
end
