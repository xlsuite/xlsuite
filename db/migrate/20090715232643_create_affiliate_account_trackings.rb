class CreateAffiliateAccountTrackings < ActiveRecord::Migration
  def self.up
    create_table :affiliate_account_trackings do |t|
      t.column :affiliate_account_id, :integer
      t.column :referrer_url, :string, :limit => 1024
      t.column :target_url, :string, :limit => 1024
      t.column :ip_address, :string, :limit => 30
      t.column :http_header, :text
      t.column :created_at, :datetime
    end
  end

  def self.down
    drop_table :affiliate_account_trackings
  end
end
