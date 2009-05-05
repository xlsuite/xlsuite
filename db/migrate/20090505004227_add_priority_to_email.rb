class AddPriorityToEmail < ActiveRecord::Migration
  def self.up
    add_column :emails, :priority, :integer
  end

  def self.down
    remove_column :emails, :priority
  end
end
