class SettingNilUuidInConfigurations < ActiveRecord::Migration
  def self.up
    Configuration.update_all("uuid = UUID()", "uuid IS NULL")
  end

  def self.down
  end
end
