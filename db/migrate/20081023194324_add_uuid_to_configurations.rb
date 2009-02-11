class AddUuidToConfigurations < ActiveRecord::Migration
  def self.up
    add_column :configurations, :uuid, :string, :limit => 36
    Configuration.update_all("uuid = UUID()")
  end

  def self.down
    remove_column :configurations, :uuid
  end
  
  class Configuration < ActiveRecord::Base; end
end
