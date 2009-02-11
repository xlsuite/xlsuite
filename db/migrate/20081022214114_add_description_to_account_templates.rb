class AddDescriptionToAccountTemplates < ActiveRecord::Migration
  def self.up
    add_column :account_templates, :description, :text
  end

  def self.down
    remove_column :account_templates, :description
  end
end
