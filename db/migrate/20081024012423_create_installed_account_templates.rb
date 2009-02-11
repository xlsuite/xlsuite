class CreateInstalledAccountTemplates < ActiveRecord::Migration
  def self.up
    create_table :installed_account_templates do |t|
      t.column :account_id, :integer
      t.column :account_template_id, :integer
      t.column :domain_patterns, :string
      t.timestamps
    end
  end

  def self.down
    drop_table :installed_account_templates
  end
end
