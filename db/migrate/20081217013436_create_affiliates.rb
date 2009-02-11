class CreateAffiliates < ActiveRecord::Migration
  def self.up
    create_table :affiliates do |t|
      t.column :target_url, :string, :limit => 1024
      t.column :source_url, :string, :limit => 1024
      t.column :party_id, :integer
      t.column :account_id, :integer
      t.timestamps
    end
  end

  def self.down
    drop_table :affiliates
  end
end
