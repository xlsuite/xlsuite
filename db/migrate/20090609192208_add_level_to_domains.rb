class AddLevelToDomains < ActiveRecord::Migration
  def self.up
    add_column :domains, :level, :tinyint
  end

  def self.down
    remove_column :domains, :level
  end
end
