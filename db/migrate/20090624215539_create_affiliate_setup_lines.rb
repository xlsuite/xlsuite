class CreateAffiliateSetupLines < ActiveRecord::Migration
  def self.up
    create_table :affiliate_setup_lines do |t|
      t.column :target_type, :string
      t.column :target_id, :integer
      t.column :percentage, :decimal, :precision => 5, :scale => 2
      t.column :level, :integer
      t.timestamps
    end
  end

  def self.down
    drop_table :affiliate_setup_lines
  end
end
