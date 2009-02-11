class AddingExtraFunctionalityColumnsToAccountTemplates < ActiveRecord::Migration
  def self.up
    add_column :account_templates, :f_cms, :boolean, :default => false
    add_column :account_templates, :f_workflows, :boolean, :default => false
  end

  def self.down
    remove_column :account_templates, :f_cms
    remove_column :account_templates, :f_workflows
  end
end
