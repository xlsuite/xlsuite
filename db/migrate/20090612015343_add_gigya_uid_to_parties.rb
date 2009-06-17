class AddGigyaUidToParties < ActiveRecord::Migration
  def self.up
    add_column :parties, :gigya_uid, :string
  end

  def self.down
    remove_column :parties, :gigya_uid
  end
end
