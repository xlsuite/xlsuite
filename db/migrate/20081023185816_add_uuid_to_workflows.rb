class AddUuidToWorkflows < ActiveRecord::Migration
  def self.up
    add_column :workflows, :uuid, :string, :limit => 36
    Workflow.update_all("uuid = UUID()")
  end

  def self.down
    remove_column :workflows, :uuid
  end
  
  class Workflow < ActiveRecord::Base; end
end
