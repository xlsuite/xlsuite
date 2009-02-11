class AddDisabledAtToSteps < ActiveRecord::Migration
  def self.up
    add_column :steps, :disabled_at, :datetime
  end

  def self.down
    remove_column :steps, :disabled_at
  end
end
