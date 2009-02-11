class AddingUnapprovedColumnsToAccountTemplates < ActiveRecord::Migration
  def self.up
    add_column :account_templates, :unapproved_at, :datetime
    add_column :account_templates, :unapproved_by_id, :integer
  end

  def self.down
    remove_column :account_templates, :unapproved_at
    remove_column :account_templates, :unapproved_by_id
  end
end
