class AddUuidToTasks < ActiveRecord::Migration
  def self.up
    add_column :tasks, :uuid, :string, :limit => 36
    Task.update_all("uuid = UUID()")
  end

  def self.down
    remove_column :tasks, :uuid
  end
  
  class Task < ActiveRecord::Base; end
end
