class AddPrivateDescriptionToGroups < ActiveRecord::Migration
  def self.up
    add_column :groups, :private_description, :text
  end

  def self.down
    remove_column :groups, :private_description
  end
end
