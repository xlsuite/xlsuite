class AddUuidToSteps < ActiveRecord::Migration
  def self.up
    add_column :steps, :uuid, :string, :limit => 36
    Step.update_all("uuid = UUID()")
  end

  def self.down
    remove_column :steps, :uuid
  end
  
  class Step < ActiveRecord::Base; end
end
